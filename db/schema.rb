# This file is autogenerated. Instead of editing this file, please use the
# migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.

ActiveRecord::Schema.define() do

  create_table "access_hits", :force => true do |t|
    t.column "site_id",          :integer
    t.column "node_id",          :integer
    t.column "remote_host",      :string,   :limit => 50
    t.column "request_time",     :datetime
    t.column "request_duration", :integer
    t.column "status",           :integer
    t.column "bytes_sent",       :integer
    t.column "request_method",   :string,   :limit => 6
    t.column "request_uri",      :string
    t.column "referer",          :string
    t.column "agent",            :string
    t.column "request_line",     :string
    t.column "mode",             :string,   :limit => 30
    t.column "format",           :string,   :limit => 10
    t.column "lang",             :string,   :limit => 6
  end

  create_table "bricks_info", :id => false, :force => true do |t|
    t.column "version", :integer
    t.column "brick",   :string
  end

  create_table "cached_pages", :force => true do |t|
    t.column "path",         :text
    t.column "expire_after", :datetime
    t.column "created_at",   :datetime
    t.column "node_id",      :integer
    t.column "site_id",      :integer
  end

  create_table "cached_pages_nodes", :id => false, :force => true do |t|
    t.column "cached_page_id", :integer
    t.column "node_id",        :integer
  end

  create_table "caches", :force => true do |t|
    t.column "updated_at",     :datetime
    t.column "visitor_id",     :integer
    t.column "visitor_groups", :string,   :limit => 200
    t.column "kpath",          :string,   :limit => 200
    t.column "context",        :integer
    t.column "content",        :text
    t.column "site_id",        :integer
  end

  create_table "comments", :force => true do |t|
    t.column "created_at",    :datetime
    t.column "updated_at",    :datetime
    t.column "status",        :integer
    t.column "discussion_id", :integer
    t.column "reply_to",      :integer
    t.column "user_id",       :integer
    t.column "title",         :string,   :limit => 250, :default => "", :null => false
    t.column "text",          :text,                                    :null => false
    t.column "author_name",   :string,   :limit => 300
    t.column "site_id",       :integer
    t.column "ip",            :string,   :limit => 200
  end

  create_table "contact_contents", :force => true do |t|
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "version_id", :integer
    t.column "first_name", :string,   :limit => 60,  :default => "", :null => false
    t.column "name",       :string,   :limit => 60,  :default => "", :null => false
    t.column "address",    :text,                                    :null => false
    t.column "zip",        :string,   :limit => 20,  :default => "", :null => false
    t.column "city",       :string,   :limit => 60,  :default => "", :null => false
    t.column "telephone",  :string,   :limit => 60,  :default => "", :null => false
    t.column "mobile",     :string,   :limit => 60,  :default => "", :null => false
    t.column "email",      :string,   :limit => 60,  :default => "", :null => false
    t.column "birthday",   :date
    t.column "site_id",    :integer
    t.column "country",    :string,   :limit => 100
  end

  create_table "data_entries", :force => true do |t|
    t.column "site_id",    :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "user_id",    :integer
    t.column "date",       :datetime
    t.column "text",       :text
    t.column "value_a",    :decimal,  :precision => 24, :scale => 8
    t.column "node_a_id",  :integer
    t.column "node_b_id",  :integer
    t.column "node_c_id",  :integer
    t.column "node_d_id",  :integer
    t.column "value_b",    :decimal,  :precision => 24, :scale => 8
  end

  create_table "discussions", :force => true do |t|
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "node_id",    :integer
    t.column "inside",     :boolean,                :default => false
    t.column "open",       :boolean,                :default => true
    t.column "lang",       :string,   :limit => 10, :default => "",    :null => false
    t.column "site_id",    :integer
  end

  create_table "document_contents", :force => true do |t|
    t.column "type",         :string,  :limit => 32
    t.column "version_id",   :integer
    t.column "name",         :string,  :limit => 200, :default => "", :null => false
    t.column "content_type", :string,  :limit => 40
    t.column "ext",          :string,  :limit => 20
    t.column "size",         :integer
    t.column "width",        :integer
    t.column "height",       :integer
    t.column "site_id",      :integer
  end

  create_table "dyn_attributes", :force => true do |t|
    t.column "owner_id",    :integer
    t.column "owner_table", :string
    t.column "key",         :string
    t.column "value",       :text
  end

  add_index "dyn_attributes", ["owner_id"], :name => "index_dyn_attributes_on_owner_id"
  add_index "dyn_attributes", ["owner_table"], :name => "index_dyn_attributes_on_owner_table"

  create_table "groups", :force => true do |t|
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "name",       :string,   :limit => 20, :default => "", :null => false
    t.column "site_id",    :integer
  end

  create_table "groups_users", :id => false, :force => true do |t|
    t.column "group_id", :integer
    t.column "user_id",  :integer
  end

  create_table "iformats", :force => true do |t|
    t.column "name",       :string,   :limit => 40
    t.column "site_id",    :integer
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "size",       :integer
    t.column "gravity",    :integer
    t.column "width",      :integer
    t.column "height",     :integer
  end

  create_table "links", :force => true do |t|
    t.column "source_id",   :integer
    t.column "target_id",   :integer
    t.column "relation_id", :integer
    t.column "status",      :integer
    t.column "comment",     :string,  :limit => 60
  end

  create_table "nodes", :force => true do |t|
    t.column "type",         :string,   :limit => 32
    t.column "event_at",     :datetime
    t.column "kpath",        :string,   :limit => 16
    t.column "created_at",   :datetime
    t.column "updated_at",   :datetime
    t.column "user_id",      :integer
    t.column "section_id",   :integer
    t.column "parent_id",    :integer
    t.column "name",         :string,   :limit => 200
    t.column "skin",         :string
    t.column "inherit",      :integer
    t.column "rgroup_id",    :integer
    t.column "wgroup_id",    :integer
    t.column "pgroup_id",    :integer
    t.column "publish_from", :datetime
    t.column "max_status",   :integer,                 :default => 30
    t.column "log_at",       :datetime
    t.column "ref_lang",     :string,   :limit => 10,  :default => "",    :null => false
    t.column "alias",        :string,   :limit => 400
    t.column "fullpath",     :text
    t.column "custom_base",  :boolean,                 :default => false
    t.column "basepath",     :text
    t.column "site_id",      :integer
    t.column "zip",          :integer
    t.column "project_id",   :integer
    t.column "position",     :float,                   :default => 0.0
    t.column "vclass_id",    :integer
    t.column "custom_a",     :integer
    t.column "custom_b",     :integer
  end

  create_table "participations", :force => true do |t|
    t.column "user_id",    :integer
    t.column "site_id",    :integer
    t.column "status",     :integer
    t.column "contact_id", :integer
    t.column "lang",       :string,  :limit => 10, :default => "", :null => false
  end

  add_index "participations", ["user_id", "site_id"], :name => "user_id", :unique => true

  create_table "relations", :force => true do |t|
    t.column "source_role",   :string,  :limit => 32
    t.column "source_kpath",  :string,  :limit => 16
    t.column "source_unique", :boolean
    t.column "source_icon",   :string,  :limit => 200
    t.column "target_role",   :string,  :limit => 32
    t.column "target_kpath",  :string,  :limit => 16
    t.column "target_unique", :boolean
    t.column "target_icon",   :string,  :limit => 200
    t.column "site_id",       :integer,                :null => false
  end

  create_table "site_attributes", :force => true do |t|
    t.column "owner_id", :integer
    t.column "key",      :string
    t.column "value",    :text
  end

  add_index "site_attributes", ["owner_id"], :name => "index_site_attributes_on_owner_id"

  create_table "sites", :force => true do |t|
    t.column "host",               :string
    t.column "root_id",            :integer
    t.column "su_id",              :integer
    t.column "anon_id",            :integer
    t.column "public_group_id",    :integer
    t.column "site_group_id",      :integer
    t.column "name",               :string
    t.column "authentication",     :boolean
    t.column "allow_private",      :boolean
    t.column "languages",          :string
    t.column "default_lang",       :string
    t.column "http_auth",          :boolean
    t.column "auto_publish",       :boolean
    t.column "redit_time",         :integer
    t.column "formats_updated_at", :datetime
  end

  create_table "template_contents", :force => true do |t|
    t.column "site_id",   :integer
    t.column "node_id",   :integer
    t.column "skin_name", :string
    t.column "format",    :string
    t.column "tkpath",    :string
    t.column "klass",     :string
    t.column "mode",      :string
  end

  create_table "users", :force => true do |t|
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "login",      :string,   :limit => 20
    t.column "password",   :string,   :limit => 40
    t.column "first_name", :string,   :limit => 60
    t.column "name",       :string,   :limit => 60
    t.column "email",      :string,   :limit => 60
    t.column "time_zone",  :string
  end

  create_table "versions", :force => true do |t|
    t.column "type",         :string,   :limit => 32
    t.column "created_at",   :datetime
    t.column "updated_at",   :datetime
    t.column "node_id",      :integer
    t.column "user_id",      :integer
    t.column "lang",         :string,   :limit => 10,  :default => "", :null => false
    t.column "publish_from", :datetime
    t.column "comment",      :text,                                    :null => false
    t.column "title",        :string,   :limit => 200, :default => "", :null => false
    t.column "summary",      :text,                                    :null => false
    t.column "text",         :text,                                    :null => false
    t.column "status",       :integer,                 :default => 30, :null => false
    t.column "number",       :integer,                 :default => 1,  :null => false
    t.column "content_id",   :integer
    t.column "site_id",      :integer
  end

  execute "ALTER TABLE versions ENGINE = MyISAM"
  execute "CREATE FULLTEXT INDEX index_versions_on_title_and_text_and_summary ON versions (title,text,summary)"

  create_table "virtual_classes", :force => true do |t|
    t.column "name",                   :string
    t.column "kpath",                  :string,  :limit => 16
    t.column "real_class",             :string,  :limit => 16
    t.column "icon",                   :string,  :limit => 200
    t.column "create_group_id",        :integer
    t.column "site_id",                :integer,                :null => false
    t.column "auto_create_discussion", :boolean
    t.column "dyn_keys",               :text
  end

  create_table "zips", :id => false, :force => true do |t|
    t.column "site_id", :integer
    t.column "zip",     :integer
  end

end
