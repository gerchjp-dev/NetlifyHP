-- ================================================
-- 東勝会社 CMSウェブサイト - 統合データベーススキーマ
-- ================================================
-- 統合元:
-- - 001_initial_schema.sql
-- - 002_fix_rls_policies.sql
-- - 20251028030922_002_admin_users_table.sql (002_fix_rls_policies.sqlより古い)
-- - 003_add_announcements.sql
-- ================================================

-- ------------------------------------------------
-- 1. エクステンションの有効化
-- ------------------------------------------------
-- uuid-osspは使われていますが、gen_random_uuid()がpgcryptoから提供されているか、
-- PostgreSQL v13以降でコア機能として組み込まれているため、両方有効化します。
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ------------------------------------------------
-- 2. 汎用関数
-- ------------------------------------------------

-- 更新日時の自動更新トリガー関数（全テーブルで共通利用）
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- ------------------------------------------------
-- 3. テーブル定義
-- ------------------------------------------------

-- 3.1 会社情報テーブル (company_info)
CREATE TABLE IF NOT EXISTS company_info (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- 会社基本情報
  company_name text NOT NULL DEFAULT '東勝会社',
  company_name_en text DEFAULT 'Tokatsu Co., Ltd.',
  company_name_zh text DEFAULT '东胜公司',

  ceo_name text DEFAULT '郭 祥',
  established date DEFAULT '2024-01-01',
  capital text DEFAULT '500万円',
  employees int DEFAULT 0,

  -- 事業内容
  business_content_ja text DEFAULT '太陽光発電パネルの点検・清掃・保守をトータルサポート',
  business_content_zh text DEFAULT '太阳能发电板检查、清洁、维护的全面支持',

  -- 連絡先情報
  phone text DEFAULT '090-7401-8083',
  fax text,
  email text DEFAULT 'guochao3000@gmail.com',

  -- 住所
  address_ja text DEFAULT '〒659-0036 兵庫県芦屋市涼風町26番14号1F',
  address_zh text DEFAULT '〒659-0036 兵库县芦屋市凉风町26番14号1F',
  postal_code text DEFAULT '659-0036',

  -- 地図
  map_embed text,

  -- ブランディング
  logo_url text,
  main_color text DEFAULT '#f59e0b',
  sub_color text DEFAULT '#0ea5e9',

  -- 代表メッセージ
  ceo_message_ja text,
  ceo_message_zh text,

  -- システムフィールド
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
COMMENT ON TABLE company_info IS '会社基本情報（1レコードのみ）';

-- 3.2 会社情報表示制御テーブル (company_info_visibility)
CREATE TABLE IF NOT EXISTS company_info_visibility (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  field_name text UNIQUE NOT NULL,
  is_visible boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
COMMENT ON TABLE company_info_visibility IS '会社情報フィールドの表示制御';

-- 3.3 サービステーブル (services)
CREATE TABLE IF NOT EXISTS services (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- サービス情報
  service_name_ja text NOT NULL,
  service_name_zh text,
  description_ja text,
  description_zh text,
  image_url text,
  icon text, -- Lucide Reactのアイコン名

  -- 表示制御
  order_index int DEFAULT 0,
  is_visible boolean DEFAULT true,
  deleted_at timestamptz,

  -- システムフィールド
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
COMMENT ON TABLE services IS 'サービス一覧（論理削除対応）';

-- 3.4 ブログ記事テーブル (blog_posts)
CREATE TABLE IF NOT EXISTS blog_posts (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- 記事情報
  title_ja text NOT NULL,
  title_zh text,
  content_ja text,
  content_zh text,
  image_url text,

  -- 公開設定
  publish_date date DEFAULT CURRENT_DATE,
  is_visible boolean DEFAULT true,
  deleted_at timestamptz,

  -- システムフィールド
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
COMMENT ON TABLE blog_posts IS 'ブログ記事・ニュース（論理削除対応）';

-- 3.5 FAQテーブル (faqs)
CREATE TABLE IF NOT EXISTS faqs (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- FAQ情報
  question_ja text NOT NULL,
  question_zh text,
  answer_ja text,
  answer_zh text,

  -- 表示制御
  order_index int DEFAULT 0,
  is_visible boolean DEFAULT true,
  deleted_at timestamptz,

  -- システムフィールド
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
COMMENT ON TABLE faqs IS 'よくある質問（論理削除対応）';

-- 3.6 緊急告知テーブル (announcements) - 003_add_announcements.sqlより
CREATE TABLE IF NOT EXISTS announcements (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- 告知情報
  title_ja text NOT NULL,
  title_zh text,
  content_ja text NOT NULL,
  content_zh text,

  -- 表示制御
  is_visible boolean DEFAULT false,
  start_date timestamptz,
  end_date timestamptz,
  priority int DEFAULT 0, -- 優先度（高いほど上に表示）

  -- スタイル設定
  background_color text DEFAULT '#fef3c7', -- 背景色（デフォルト: 薄い黄色）
  text_color text DEFAULT '#92400e', -- テキスト色（デフォルト: 茶色）

  -- 論理削除
  deleted_at timestamptz,

  -- システムフィールド
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
COMMENT ON TABLE announcements IS '会社からの緊急告知（論理削除対応）';

-- 3.7 管理者ユーザーテーブル (admin_users) - 統合・重複解消
-- 20251028030922_002_admin_users_table.sqlと001_initial_schema.sqlで重複していた定義を統合
CREATE TABLE IF NOT EXISTS admin_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  username text UNIQUE NOT NULL,
  password_hash text NOT NULL,
  display_name text NOT NULL,
  is_active boolean DEFAULT true NOT NULL,
  last_login_at timestamptz,
  created_at timestamptz DEFAULT now() NOT NULL,
  updated_at timestamptz DEFAULT now() NOT NULL
);
COMMENT ON TABLE admin_users IS '管理者ユーザーアカウント';


-- ------------------------------------------------
-- 4. トリガー設定
-- ------------------------------------------------

-- company_infoの更新日時を自動更新
CREATE TRIGGER update_company_info_updated_at
  BEFORE UPDATE ON company_info
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- company_info_visibilityの更新日時を自動更新
CREATE TRIGGER update_company_info_visibility_updated_at
  BEFORE UPDATE ON company_info_visibility
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- servicesの更新日時を自動更新
CREATE TRIGGER update_services_updated_at
  BEFORE UPDATE ON services
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- blog_postsの更新日時を自動更新
CREATE TRIGGER update_blog_posts_updated_at
  BEFORE UPDATE ON blog_posts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- faqsの更新日時を自動更新
CREATE TRIGGER update_faqs_updated_at
  BEFORE UPDATE ON faqs
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- announcementsの更新日時を自動更新
CREATE TRIGGER update_announcements_updated_at
  BEFORE UPDATE ON announcements
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- admin_usersの更新日時を自動更新
-- 20251028030922_002_admin_users_table.sqlのカスタム関数は重複するため、汎用関数に統合します
CREATE TRIGGER update_admin_users_updated_at
  BEFORE UPDATE ON admin_users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();


-- ------------------------------------------------
-- 5. インデックス作成
-- ------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_services_order ON services(order_index);
CREATE INDEX IF NOT EXISTS idx_services_visible ON services(is_visible, deleted_at);

CREATE INDEX IF NOT EXISTS idx_blog_posts_publish_date ON blog_posts(publish_date DESC);
CREATE INDEX IF NOT EXISTS idx_blog_posts_visible ON blog_posts(is_visible, deleted_at);

CREATE INDEX IF NOT EXISTS idx_faqs_order ON faqs(order_index);
CREATE INDEX IF NOT EXISTS idx_faqs_visible ON faqs(is_visible, deleted_at);

CREATE INDEX IF NOT EXISTS idx_announcements_visible ON announcements(is_visible, deleted_at);
CREATE INDEX IF NOT EXISTS idx_announcements_priority ON announcements(priority DESC);
CREATE INDEX IF NOT EXISTS idx_announcements_dates ON announcements(start_date, end_date);


-- ------------------------------------------------
-- 6. 管理者認証用関数
-- ------------------------------------------------

-- パスワード検証関数（username/password認証用）
CREATE OR REPLACE FUNCTION verify_admin_credentials(
  p_username text,
  p_password text
)
RETURNS TABLE(
  user_id uuid,
  username text,
  display_name text
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    au.id,
    au.username,
    au.display_name
  FROM admin_users au
  WHERE
    au.username = p_username
    AND au.password_hash = crypt(p_password, au.password_hash)
    AND au.is_active = true;

  -- 最終ログイン日時を更新
  UPDATE admin_users
  SET last_login_at = now()
  WHERE admin_users.username = p_username;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- パスワード変更関数
CREATE OR REPLACE FUNCTION change_admin_password(
  p_user_id uuid,
  p_old_password text,
  p_new_password text
)
RETURNS boolean AS $$
DECLARE
  v_current_hash text;
BEGIN
  -- 現在のパスワードハッシュを取得
  SELECT password_hash INTO v_current_hash
  FROM admin_users
  WHERE id = p_user_id;

  -- 古いパスワードを検証
  IF v_current_hash = crypt(p_old_password, v_current_hash) THEN
    -- 新しいパスワードを設定
    UPDATE admin_users
    SET password_hash = crypt(p_new_password, gen_salt('bf'))
    WHERE id = p_user_id;

    RETURN true;
  ELSE
    RETURN false;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ------------------------------------------------
-- 7. RLS (Row Level Security) 有効化とポリシー設定
-- ------------------------------------------------

-- RLS有効化
ALTER TABLE company_info ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_info_visibility ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE blog_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE faqs ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY; -- 003_add_announcements.sqlより
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- 既存のポリシーを削除（002_fix_rls_policies.sqlで削除されていますが、念のため再度実行可能にしておく）
DROP POLICY IF EXISTS "認証ユーザーは会社情報を編集可能" ON company_info;
DROP POLICY IF EXISTS "認証ユーザーは会社情報表示設定を編集可能" ON company_info_visibility;
DROP POLICY IF EXISTS "認証ユーザーは全サービスを閲覧可能" ON services;
DROP POLICY IF EXISTS "認証ユーザーはサービスを追加可能" ON services;
DROP POLICY IF EXISTS "認証ユーザーはサービスを更新可能" ON services;
DROP POLICY IF EXISTS "認証ユーザーはサービスを削除可能" ON services;
DROP POLICY IF EXISTS "認証ユーザーは全ブログ記事を閲覧可能" ON blog_posts;
DROP POLICY IF EXISTS "認証ユーザーはブログ記事を追加可能" ON blog_posts;
DROP POLICY IF EXISTS "認証ユーザーはブログ記事を更新可能" ON blog_posts;
DROP POLICY IF EXISTS "認証ユーザーはブログ記事を削除可能" ON blog_posts;
DROP POLICY IF EXISTS "認証ユーザーは全FAQを閲覧可能" ON faqs;
DROP POLICY IF EXISTS "認証ユーザーはFAQを追加可能" ON faqs;
DROP POLICY IF EXISTS "認証ユーザーはFAQを更新可能" ON faqs;
DROP POLICY IF EXISTS "認証ユーザーはFAQを削除可能" ON faqs;
-- admin_usersのポリシーは001/002_admin_usersで定義されたTO authenticatedが不要になるため削除
DROP POLICY IF EXISTS "Authenticated users can view admin users" ON admin_users;
DROP POLICY IF EXISTS "Authenticated users can update own profile" ON admin_users;


-- 公開ポリシー（フロントエンド表示用）
-- 会社情報: 全ユーザー閲覧可能
CREATE POLICY "会社情報は誰でも閲覧可能"
  ON company_info FOR SELECT
  USING (true);

CREATE POLICY "会社情報表示設定は誰でも閲覧可能"
  ON company_info_visibility FOR SELECT
  USING (true);

-- サービス: 表示可能かつ削除されていないもののみ
CREATE POLICY "公開サービスは誰でも閲覧可能"
  ON services FOR SELECT
  USING (is_visible = true AND deleted_at IS NULL);

-- ブログ: 表示可能かつ削除されていないもののみ
CREATE POLICY "公開ブログ記事は誰でも閲覧可能"
  ON blog_posts FOR SELECT
  USING (is_visible = true AND deleted_at IS NULL);

-- FAQ: 表示可能かつ削除されていないもののみ
CREATE POLICY "公開FAQは誰でも閲覧可能"
  ON faqs FOR SELECT
  USING (is_visible = true AND deleted_at IS NULL);

-- 告知: 表示可能、削除されておらず、期間内の告知のみ
CREATE POLICY "公開告知は誰でも閲覧可能"
  ON announcements FOR SELECT
  USING (
    is_visible = true
    AND deleted_at IS NULL
    AND (start_date IS NULL OR start_date <= now())
    AND (end_date IS NULL OR end_date >= now())
  );


-- 管理者ポリシー（カスタム認証対応 - 002_fix_rls_policies.sqlの最終形）
-- 警告: カスタム認証を使用しているため、anon keyでも管理操作を許可します。
--       クライアント側で必ずログイン状態を確認してから操作を実行してください。

-- 会社情報: 全ユーザーが全操作可能
CREATE POLICY "Anyone can manage company info"
  ON company_info FOR ALL
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Anyone can manage company info visibility"
  ON company_info_visibility FOR ALL
  USING (true)
  WITH CHECK (true);

-- サービス: 全ユーザーが全データ閲覧・編集可能
CREATE POLICY "Anyone can view all services"
  ON services FOR SELECT
  USING (true);

CREATE POLICY "Anyone can insert services"
  ON services FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can update services"
  ON services FOR UPDATE
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Anyone can delete services"
  ON services FOR DELETE
  USING (true);

-- ブログ: 全ユーザーが全データ閲覧・編集可能
CREATE POLICY "Anyone can view all blog posts"
  ON blog_posts FOR SELECT
  USING (true);

CREATE POLICY "Anyone can insert blog posts"
  ON blog_posts FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can update blog posts"
  ON blog_posts FOR UPDATE
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Anyone can delete blog posts"
  ON blog_posts FOR DELETE
  USING (true);

-- FAQ: 全ユーザーが全データ閲覧・編集可能
CREATE POLICY "Anyone can view all faqs"
  ON faqs FOR SELECT
  USING (true);

CREATE POLICY "Anyone can insert faqs"
  ON faqs FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can update faqs"
  ON faqs FOR UPDATE
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Anyone can delete faqs"
  ON faqs FOR DELETE
  USING (true);

-- 告知: 全ユーザーが全データ閲覧・編集可能
CREATE POLICY "認証ユーザーは全告知を閲覧可能"
  ON announcements FOR SELECT
  USING (true);

CREATE POLICY "認証ユーザーは告知を追加可能"
  ON announcements FOR INSERT
  WITH CHECK (true);

CREATE POLICY "認証ユーザーは告知を更新可能"
  ON announcements FOR UPDATE
  USING (true)
  WITH CHECK (true);

CREATE POLICY "認証ユーザーは告知を削除可能"
  ON announcements FOR DELETE
  USING (true);

-- 管理者ユーザー: 全ての管理者情報を閲覧可能（カスタム認証対応のため、誰でも閲覧可能に）
CREATE POLICY "Anyone can view admin users"
  ON admin_users FOR SELECT
  USING (true);

CREATE POLICY "Anyone can update own profile"
  ON admin_users FOR UPDATE
  USING (true)
  WITH CHECK (true);


-- ------------------------------------------------
-- 8. 初期データ投入
-- ------------------------------------------------

-- デフォルト管理者アカウントの作成
INSERT INTO admin_users (username, password_hash, display_name)
VALUES (
  'admin',
  crypt('admin', gen_salt('bf')),
  '管理者'
)
ON CONFLICT (username) DO NOTHING;


-- ------------------------------------------------
-- 9. 完了メッセージ
-- ------------------------------------------------

DO $$
BEGIN
  RAISE NOTICE '✅ データベーススキーマの統合・作成が完了しました！';
  RAISE NOTICE '⚠️  RLSポリシーはカスタム認証に対応するため、全ユーザーアクセスを許可する設定になっています。フロント側で必ず認証チェックを行ってください。';
  RAISE NOTICE '📋 次のステップ: 必要に応じて seed.sql でサンプルデータを投入してください。';
END $$;
