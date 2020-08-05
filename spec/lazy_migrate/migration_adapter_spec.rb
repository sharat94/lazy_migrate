# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LazyMigrate::MigrationAdapter do
  let(:rails_root) { Rails.root }

  let(:create_books_migration_status) {
    { status: "up", version: 20200804231712, name: "Create books", has_file: true, current: false }
  }

  let(:add_author_migration_status_status) { 'up' }
  let(:add_author_migration_status) {
    { status: add_author_migration_status_status, version: 20200804234040, name: "Add book author", has_file: true, current: false }
  }

  let(:add_page_count_migration_status) {
    { status: "down", version: 20200804234057, name: "Add book page count", has_file: true, current: false }
  }

  let(:add_rating_migration_status) {
    { status: "up", version: 20200804234111, name: "Add book rating", has_file: true, current: true }
  }

  let(:migrations) {
    [
      add_rating_migration_status,
      add_page_count_migration_status,
      add_author_migration_status,
      create_books_migration_status,
    ]
  }

  let(:migration_adapter) { LazyMigrate::NewMigrationAdapter.new }

  let(:new_version) { 30900804234040 }

  def find_support_folder
    File.join(File.dirname(File.dirname(__FILE__)), 'support')
  end

  before do
    # prepare the db directory
    support_folder = find_support_folder
    db_dir = ActiveRecord::Tasks::DatabaseTasks.db_dir

    schema_filename = File.join(db_dir, 'schema.rb')
    FileUtils.cp(File.join(support_folder, 'mock_schema.rb'), schema_filename)

    migrate_dir = File.join(db_dir, 'migrate')
    FileUtils.rm_rf(migrate_dir)
    FileUtils.cp_r(File.join(support_folder, 'mock_migrations/default/.'), migrate_dir)

    # does the db exist?
    if !File.exist?(File.join(db_dir, 'test.sqlite3'))
      ActiveRecord::Migrations.create
    end

    ActiveRecord::Migration.drop_table(:books) if ActiveRecord::Base.connection.table_exists?(:books)
    ActiveRecord::Migration.create_table "books", force: :cascade do |t|
      t.string "name"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    ActiveRecord::SchemaMigration.delete_all

    migrations.sort { |m| m[:version] }.each do |migration|
      if migration[:status] == 'up'
        ActiveRecord::SchemaMigration.create(version: migration[:version])
      end
    end
  end

  describe '.find_migrations' do
    it "finds migrations" do
      expect(migration_adapter.find_migrations).to eq(migrations)
    end
  end

  describe '.replace_version_in_filename' do
    let(:filename) { '20200804231712_create_books.rb' }

    subject { migration_adapter.replace_version_in_filename(filename, new_version) }

    it { is_expected.to eq "./#{new_version}_create_books.rb" }
  end

  describe '.bring_to_top' do
    let(:migration) { add_author_migration_status }
    let(:rerun) { false }

    subject { migration_adapter.bring_to_top(migration: migration, ask_for_rerun: -> { rerun }) }

    before do
      expect(ActiveRecord::Migration).to receive(:next_migration_number).with(add_rating_migration_status[:version] + 1).and_return(new_version.to_s)
    end

    shared_examples 'renames file' do
      it 'renames file to have new version' do
        subject

        new_file_exists = File.exist?(
          File.join(ActiveRecord::Tasks::DatabaseTasks.db_dir, 'migrate', "#{new_version}_add_book_author.rb")
        )

        old_file_exists = File.exist?(
          File.join(ActiveRecord::Tasks::DatabaseTasks.db_dir, 'migrate', '20200804234040_add_book_author.rb')
        )

        expect(new_file_exists).to be true
        expect(old_file_exists).to be false
      end
    end

    shared_examples 'does not run migrations' do
      it 'does not run migrations' do
        expect(Rails.logger).to receive(:info).with("Migrating to AddBookAuthor (20200804234040)").never
        expect(Rails.logger).to receive(:info).with("Migrating to AddBookAuthor (#{new_version})").never

        subject
      end
    end

    context 'when migration is down' do
      let(:add_author_migration_status_status) { 'down' }

      include_examples 'renames file'
      include_examples 'does not run migrations'

      it 'does not change schema migration table' do
        expect { subject }.not_to(change { ActiveRecord::SchemaMigration.all.map(&:version) }.from([
          create_books_migration_status[:version],
          add_rating_migration_status[:version],
        ]))
      end
    end

    context 'when migration is up' do
      let(:migration) { add_author_migration_status }

      shared_examples 'swaps version in schema_versions' do
        it 'swaps version in schema_versions' do
          expect { subject }
            .to change { ActiveRecord::SchemaMigration.all.map(&:version) }
            .from([
              create_books_migration_status[:version],
              add_author_migration_status[:version],
              add_rating_migration_status[:version],
            ])
            .to([
              create_books_migration_status[:version],
              add_rating_migration_status[:version],
              new_version,
            ])
        end
      end

      context 'when we do not want to rerun the migration' do
        include_examples 'renames file'
        include_examples 'swaps version in schema_versions'
        include_examples 'does not run migrations'
      end

      context 'when we want to rerun the migration' do
        let(:rerun) { true }

        include_examples 'renames file'
        include_examples 'swaps version in schema_versions'

        it 'brings to top and reruns' do
          expect(Rails.logger).to receive(:info).with('Migrating to AddBookAuthor (20200804234040)').ordered
          expect(Rails.logger).to receive(:info).with("Migrating to AddBookAuthor (#{new_version})").ordered

          subject
        end
      end
    end
  end

  describe '.load_migration_paths' do
    it 'loads newly created migration file' do
      support_folder = find_support_folder
      migrate_dir = File.join(ActiveRecord::Tasks::DatabaseTasks.db_dir, 'migrate')

      FileUtils.cp(File.join(support_folder, 'mock_migrations/20200804235555_add_book_weight.rb'), migrate_dir)

      migration_adapter.load_migration_paths

      # confirming that it's defined
      expect { AddBookWeight }.not_to raise_error
    end
  end

  describe '.dump_schema' do
    it 'dumps schema' do
      schema_file = File.join(ActiveRecord::Tasks::DatabaseTasks.db_dir, "schema.rb")

      ActiveRecord::SchemaMigration.create(version: 4020_08_04_234040)

      migration_adapter.dump_schema

      expect(File.read(schema_file)).to include('4020_08_04_234040')
    end
  end

  describe '.up' do
    it 'ups a migration' do
      migration_adapter.up(add_page_count_migration_status[:version])

      expect(ActiveRecord::SchemaMigration.find_by(version: add_author_migration_status[:version])).to be_present
    end
  end

  describe '.down' do
    it 'downs a migration' do
      migration_adapter.down(add_author_migration_status[:version])

      expect(ActiveRecord::SchemaMigration.find_by(version: add_author_migration_status[:version])).to be nil
    end
  end

  describe '.migrate' do
    let(:add_author_migration_status_status) { 'down' }

    subject { migration_adapter.migrate(add_page_count_migration_status[:version]) }

    it 'migrates up to and including migration' do
      expect { subject }
        .to change { ActiveRecord::SchemaMigration.all.map(&:version) }
        .from([
          create_books_migration_status[:version],
          add_rating_migration_status[:version],
        ])
        .to([
          create_books_migration_status[:version],
          add_rating_migration_status[:version],
          add_author_migration_status[:version],
          add_page_count_migration_status[:version],
        ])
    end
  end

  describe '.rollback' do
    let(:add_author_migration_status_status) { 'up' }

    subject { migration_adapter.rollback(add_author_migration_status[:version]) }

    it 'rolls back to before migration' do
      expect { subject }
        .to change { ActiveRecord::SchemaMigration.all.map(&:version) }
        .from([
          create_books_migration_status[:version],
          add_author_migration_status[:version],
          add_rating_migration_status[:version],
        ])
        .to([
          create_books_migration_status[:version],
        ])
    end
  end
end