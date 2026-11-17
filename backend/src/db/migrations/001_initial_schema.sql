-- Restaurants (multi-restaurant ready)
CREATE TABLE restaurants (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  slug        TEXT NOT NULL UNIQUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Staff users
CREATE TABLE users (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id  UUID NOT NULL REFERENCES restaurants(id),
  name           TEXT NOT NULL,
  email          TEXT NOT NULL UNIQUE,
  password_hash  TEXT NOT NULL,
  role           TEXT NOT NULL CHECK (role IN ('OWNER','CASHIER','WAITER','KITCHEN')),
  is_active      BOOLEAN NOT NULL DEFAULT true,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Physical tables
CREATE TABLE tables (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id  UUID NOT NULL REFERENCES restaurants(id),
  label          TEXT NOT NULL,
  qr_token       TEXT NOT NULL UNIQUE,
  UNIQUE (restaurant_id, label)
);

-- Menu
CREATE TABLE categories (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id  UUID NOT NULL REFERENCES restaurants(id),
  name           TEXT NOT NULL,
  sort_order     INT NOT NULL DEFAULT 0
);

CREATE TABLE menu_items (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id   UUID NOT NULL REFERENCES categories(id),
  name          TEXT NOT NULL,
  price_paise   INT NOT NULL CHECK (price_paise >= 0),
  is_veg        BOOLEAN NOT NULL DEFAULT true,
  is_available  BOOLEAN NOT NULL DEFAULT true,
  image_url     TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Table sessions (a group's visit, can cover many tables)
CREATE TABLE table_sessions (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id  UUID NOT NULL REFERENCES restaurants(id),
  status         TEXT NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN','BILLED','CLOSED')),
  opened_by      UUID REFERENCES users(id),
  opened_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  closed_at      TIMESTAMPTZ
);

CREATE TABLE session_tables (
  session_id  UUID NOT NULL REFERENCES table_sessions(id) ON DELETE CASCADE,
  table_id    UUID NOT NULL REFERENCES tables(id),
  is_active   BOOLEAN NOT NULL DEFAULT true,
  PRIMARY KEY (session_id, table_id)
);

-- A table can be in only ONE active session at a time (enforced by the database)
CREATE UNIQUE INDEX one_active_session_per_table
  ON session_tables (table_id) WHERE is_active;

-- Orders
CREATE TABLE orders (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id       UUID NOT NULL REFERENCES table_sessions(id),
  source_table_id  UUID REFERENCES tables(id),
  status           TEXT NOT NULL DEFAULT 'PLACED'
                   CHECK (status IN ('PLACED','PREPARING','READY','SERVED','CANCELLED')),
  cancel_reason    TEXT,
  idempotency_key  TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (session_id, idempotency_key)
);

CREATE TABLE order_items (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id              UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  menu_item_id          UUID NOT NULL REFERENCES menu_items(id),
  name_snapshot         TEXT NOT NULL,
  price_paise_snapshot  INT NOT NULL CHECK (price_paise_snapshot >= 0),
  quantity              INT NOT NULL CHECK (quantity > 0),
  note                  TEXT
);

-- Payments
CREATE TABLE payments (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id    UUID NOT NULL REFERENCES table_sessions(id),
  amount_paise  INT NOT NULL CHECK (amount_paise > 0),
  method        TEXT NOT NULL CHECK (method IN ('CASH','UPI')),
  paid_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes for the queries we run constantly
CREATE INDEX idx_orders_session        ON orders (session_id);
CREATE INDEX idx_orders_status_created ON orders (status, created_at);
CREATE INDEX idx_order_items_order     ON order_items (order_id);
CREATE INDEX idx_menu_items_category   ON menu_items (category_id);
CREATE INDEX idx_sessions_status       ON table_sessions (restaurant_id, status);