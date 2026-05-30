-- Smart University IoT — Full Database Schema
-- Supabase PostgreSQL with Realtime + RLS
-- Generated: 2026-05-30

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- ROOMS (metadata table for each monitored room)
-- ============================================
CREATE TABLE IF NOT EXISTS public.rooms (
  room_id   text PRIMARY KEY,
  name      text NOT NULL,
  capacity  integer DEFAULT 30,
  stream_ws_url text DEFAULT '',
  operational_start text DEFAULT '07:00',
  operational_end   text DEFAULT '22:00',
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

COMMENT ON TABLE public.rooms IS 'Monitored rooms / classrooms';

-- Seed default room
INSERT INTO public.rooms (room_id, name, capacity, stream_ws_url)
VALUES ('salle1', 'Salle 1', 30, 'ws://192.168.1.100:3000/stream')
ON CONFLICT (room_id) DO NOTHING;

-- Pre-provision all expected devices so FK constraints never fail
INSERT INTO public.device_status (device_id, room_id, status)
VALUES ('esp8266_salle1', 'salle1', 'online')
ON CONFLICT (device_id) DO NOTHING;

INSERT INTO public.device_status (device_id, room_id, status)
VALUES ('esp32_salle1', 'salle1', 'online')
ON CONFLICT (device_id) DO NOTHING;

INSERT INTO public.device_status (device_id, room_id, status)
VALUES ('cam_salle1', 'salle1', 'online')
ON CONFLICT (device_id) DO NOTHING;

-- ============================================
-- STUDENTS
-- ============================================
DO $$ BEGIN
  CREATE SEQUENCE IF NOT EXISTS students_id_seq START 1;
EXCEPTION WHEN duplicate_table THEN
  -- sequence already exists
END $$;

CREATE TABLE IF NOT EXISTS public.students (
  id         integer PRIMARY KEY DEFAULT nextval('students_id_seq'),
  name       text NOT NULL,
  email      text UNIQUE,
  card_id    text,
  created_at timestamp with time zone DEFAULT now()
);

-- ============================================
-- RFID CARDS
-- ============================================
DO $$ BEGIN
  CREATE SEQUENCE IF NOT EXISTS rfid_cards_id_seq START 1;
END $$;

CREATE TABLE IF NOT EXISTS public.rfid_cards (
  id         integer PRIMARY KEY DEFAULT nextval('rfid_cards_id_seq'),
  rfid_uid   text NOT NULL UNIQUE,
  student_id integer REFERENCES public.students(id) ON DELETE SET NULL,
  is_active  boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now()
);

-- ============================================
-- SENSOR DATA (telemetry from ESP8266 / ESP32)
-- ============================================
DO $$ BEGIN
  CREATE SEQUENCE IF NOT EXISTS sensor_data_id_seq START 1;
END $$;

CREATE TABLE IF NOT EXISTS public.sensor_data (
  id          integer PRIMARY KEY DEFAULT nextval('sensor_data_id_seq'),
  room_id     text NOT NULL REFERENCES public.rooms(room_id) ON DELETE CASCADE,
  device_id   text NOT NULL,
  sensor_type text NOT NULL,
  value       numeric,
  unit        text,
  timestamp   timestamp with time zone NOT NULL,
  received_at timestamp with time zone DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sensor_data_room ON public.sensor_data(room_id);
CREATE INDEX IF NOT EXISTS idx_sensor_data_type ON public.sensor_data(sensor_type);
CREATE INDEX IF NOT EXISTS idx_sensor_data_ts  ON public.sensor_data(timestamp DESC);

-- ============================================
-- ACTUATORS (servo, buzzer, LED RGB, relay)
-- ============================================
DO $$ BEGIN
  CREATE SEQUENCE IF NOT EXISTS actuators_id_seq START 1;
END $$;

CREATE TABLE IF NOT EXISTS public.actuators (
  id            integer PRIMARY KEY DEFAULT nextval('actuators_id_seq'),
  room_id       text NOT NULL REFERENCES public.rooms(room_id) ON DELETE CASCADE,
  actuator_id   text NOT NULL,
  actuator_type text NOT NULL,
  current_state text DEFAULT 'off',
  command       text,
  target_device text DEFAULT 'esp32',
  settings      jsonb DEFAULT '{}',
  updated_at    timestamp with time zone DEFAULT now()
);

-- Deduplicate before creating unique index (keep the highest id)
DELETE FROM public.actuators a
USING public.actuators b
WHERE a.id < b.id
  AND a.room_id = b.room_id
  AND a.actuator_id = b.actuator_id;

CREATE UNIQUE INDEX IF NOT EXISTS idx_actuators_room_type ON public.actuators(room_id, actuator_id);

-- ============================================
-- DEVICE STATUS (heartbeat table)
-- ============================================
CREATE TABLE IF NOT EXISTS public.device_status (
  device_id   text PRIMARY KEY,
  room_id     text REFERENCES public.rooms(room_id) ON DELETE SET NULL,
  last_seen   timestamp with time zone,
  status      text DEFAULT 'offline',
  ip_address  inet,
  rssi        integer,
  uptime_ms   bigint,
  updated_at  timestamp with time zone DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_device_status_room ON public.device_status(room_id);

-- ============================================
-- ATTENDANCE (RFID presence events)
-- ============================================
DO $$ BEGIN
  CREATE SEQUENCE IF NOT EXISTS attendance_id_seq START 1;
END $$;

CREATE TABLE IF NOT EXISTS public.attendance (
  id         integer PRIMARY KEY DEFAULT nextval('attendance_id_seq'),
  room_id    text NOT NULL REFERENCES public.rooms(room_id) ON DELETE CASCADE,
  tag_id     text NOT NULL,
  student_id integer REFERENCES public.students(id) ON DELETE SET NULL,
  timestamp  timestamp with time zone NOT NULL,
  status     text DEFAULT 'present',
  created_at timestamp with time zone DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_attendance_room ON public.attendance(room_id);
CREATE INDEX IF NOT EXISTS idx_attendance_ts   ON public.attendance(timestamp DESC);

-- ============================================
-- ROOM OCCUPANCY (AI / mock data)
-- ============================================
DO $$ BEGIN
  CREATE SEQUENCE IF NOT EXISTS room_occupancy_id_seq START 1;
END $$;

CREATE TABLE IF NOT EXISTS public.room_occupancy (
  id           integer PRIMARY KEY DEFAULT nextval('room_occupancy_id_seq'),
  room_id      text NOT NULL REFERENCES public.rooms(room_id) ON DELETE CASCADE,
  person_count integer NOT NULL DEFAULT 0,
  confidence   numeric,
  timestamp    timestamp with time zone NOT NULL,
  created_at   timestamp with time zone DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_occupancy_room ON public.room_occupancy(room_id);
CREATE INDEX IF NOT EXISTS idx_occupancy_ts   ON public.room_occupancy(timestamp DESC);

-- Seed mock occupancy for demo
INSERT INTO public.room_occupancy (room_id, person_count, confidence, timestamp)
VALUES ('salle1', 0, 0.95, now())
ON CONFLICT DO NOTHING;

-- ============================================
-- ALERTS (intrusion + threshold)
-- ============================================
DO $$ BEGIN
  CREATE SEQUENCE IF NOT EXISTS alerts_id_seq START 1;
END $$;

CREATE TABLE IF NOT EXISTS public.alerts (
  id           integer PRIMARY KEY DEFAULT nextval('alerts_id_seq'),
  room_id      text NOT NULL REFERENCES public.rooms(room_id) ON DELETE CASCADE,
  alert_type   text NOT NULL,  -- 'intrusion', 'threshold_gas', 'threshold_temp', etc.
  severity     text DEFAULT 'medium',
  message      text,
  person_count integer,
  timestamp    timestamp with time zone NOT NULL,
  acknowledged boolean DEFAULT false,
  created_at   timestamp with time zone DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_alerts_room ON public.alerts(room_id);
CREATE INDEX IF NOT EXISTS idx_alerts_ts   ON public.alerts(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_ack  ON public.alerts(acknowledged);

-- ============================================
-- REALTIME PUBLICATION
-- ============================================
DO $$
DECLARE
  tbl    text;
  tables text[] := ARRAY[
    'rooms', 'sensor_data', 'actuators', 'device_status',
    'attendance', 'room_occupancy', 'alerts', 'rfid_cards', 'students'
  ];
BEGIN
  FOREACH tbl IN ARRAY tables LOOP
    BEGIN
      EXECUTE format(
        'ALTER PUBLICATION supabase_realtime ADD TABLE public.%I;',
        tbl
      );
    EXCEPTION WHEN duplicate_object THEN
      -- already in publication, skip
    END;
  END LOOP;
END $$;

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.rooms            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sensor_data      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.actuators        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_status    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_occupancy   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.alerts           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rfid_cards       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students         ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read all data (academic demo context)
-- In production, restrict by user role / building / department

DROP POLICY IF EXISTS "Allow authenticated read rooms" ON public.rooms;
CREATE POLICY "Allow authenticated read rooms"
  ON public.rooms FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow authenticated read sensor_data" ON public.sensor_data;
CREATE POLICY "Allow authenticated read sensor_data"
  ON public.sensor_data FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow authenticated read actuators" ON public.actuators;
CREATE POLICY "Allow authenticated read actuators"
  ON public.actuators FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow authenticated update actuators" ON public.actuators;
CREATE POLICY "Allow authenticated update actuators"
  ON public.actuators FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow authenticated insert actuators" ON public.actuators;
CREATE POLICY "Allow authenticated insert actuators"
  ON public.actuators FOR INSERT TO authenticated WITH CHECK (true);

DROP POLICY IF EXISTS "Allow authenticated read device_status" ON public.device_status;
CREATE POLICY "Allow authenticated read device_status"
  ON public.device_status FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow authenticated read attendance" ON public.attendance;
CREATE POLICY "Allow authenticated read attendance"
  ON public.attendance FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow authenticated read room_occupancy" ON public.room_occupancy;
CREATE POLICY "Allow authenticated read room_occupancy"
  ON public.room_occupancy FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow authenticated read alerts" ON public.alerts;
CREATE POLICY "Allow authenticated read alerts"
  ON public.alerts FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow authenticated update alerts" ON public.alerts;
CREATE POLICY "Allow authenticated update alerts"
  ON public.alerts FOR UPDATE TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow authenticated read rfid_cards" ON public.rfid_cards;
CREATE POLICY "Allow authenticated read rfid_cards"
  ON public.rfid_cards FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "Allow authenticated read students" ON public.students;
CREATE POLICY "Allow authenticated read students"
  ON public.students FOR SELECT TO authenticated USING (true);

-- ============================================
-- THRESHOLD CONFIGURATION (for bridge-server alerts)
-- ============================================
DO $$ BEGIN
  CREATE SEQUENCE IF NOT EXISTS thresholds_id_seq START 1;
END $$;

CREATE TABLE IF NOT EXISTS public.thresholds (
  id          integer PRIMARY KEY DEFAULT nextval('thresholds_id_seq'),
  sensor_type text NOT NULL UNIQUE,
  max_value   numeric,
  min_value   numeric,
  unit        text,
  updated_at  timestamp with time zone DEFAULT now()
);

ALTER TABLE public.thresholds ENABLE ROW LEVEL SECURITY;

-- Seed default thresholds
INSERT INTO public.thresholds (sensor_type, max_value, min_value, unit) VALUES
  ('gas',         400,  0,  'ppm'),
  ('temperature',  40,  5,  'C'),
  ('humidity',     80, 20,  '%'),
  ('distance',    100,  0,  'cm')
ON CONFLICT (sensor_type) DO NOTHING;

DROP POLICY IF EXISTS "Allow authenticated read thresholds" ON public.thresholds;
CREATE POLICY "Allow authenticated read thresholds"
  ON public.thresholds FOR SELECT TO authenticated USING (true);


INSERT INTO public.device_status (device_id, room_id, status)
VALUES ('esp8266_salle1', 'salle1', 'online')
ON CONFLICT (device_id) DO NOTHING;

  -- Actuators are configured by humans; room must exist first
ALTER TABLE public.actuators
  ADD CONSTRAINT actuators_room_id_fkey
  FOREIGN KEY (room_id) REFERENCES public.rooms(room_id);

-- Attendance is written by your backend after RFID scan validation
ALTER TABLE public.attendance
  ADD CONSTRAINT attendance_room_id_fkey
    FOREIGN KEY (room_id) REFERENCES public.rooms(room_id),
  ADD CONSTRAINT attendance_student_id_fkey
    FOREIGN KEY (student_id) REFERENCES public.students(id),
  ADD CONSTRAINT attendance_tag_id_fkey
    FOREIGN KEY (tag_id) REFERENCES public.rfid_cards(rfid_uid);

-- device_status rows are provisioned, not auto-created by the device
ALTER TABLE public.device_status
  ADD CONSTRAINT device_status_room_id_fkey
  FOREIGN KEY (room_id) REFERENCES public.rooms(room_id);



  ALTER TABLE public.sensor_data
  ADD CONSTRAINT sensor_data_room_id_fkey
    FOREIGN KEY (room_id) REFERENCES public.rooms(room_id),
  ADD CONSTRAINT sensor_data_device_id_fkey
    FOREIGN KEY (device_id) REFERENCES public.device_status(device_id);

ALTER TABLE public.alerts
  ADD CONSTRAINT alerts_room_id_fkey
  FOREIGN KEY (room_id) REFERENCES public.rooms(room_id);

ALTER TABLE public.room_occupancy
  ADD CONSTRAINT room_occupancy_room_id_fkey
  FOREIGN KEY (room_id) REFERENCES public.rooms(room_id);
  ALTER TABLE public.students DROP COLUMN card_id;