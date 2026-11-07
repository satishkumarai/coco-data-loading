-- ==============================================================================
-- pipe_monitoring.sql
-- Production Snowpipe Monitoring, Health Verification & Latency Analytics
-- ==============================================================================

-- 1. Real-Time Deep Inspection of SYSTEM$PIPE_STATUS
-- Returns execution state, queue backlog, message arrival timestamps, and error states
WITH pipe_diag AS (
  SELECT PARSE_JSON(SYSTEM$PIPE_STATUS('RAW_DB.INGEST_SCHEMA.PIPE_AWS_EVENTS_AUTOINGEST')) AS status
)
SELECT
  status:executionState::STRING AS execution_state,
  status:pendingFileCount::NUMBER AS pending_file_count,
  status:lastReceivedMessageTimestamp::TIMESTAMP_NTZ AS last_received_notification,
  status:lastForwardedMessageTimestamp::TIMESTAMP_NTZ AS last_forwarded_message,
  status:lastForwardedFilePath::STRING AS last_forwarded_file_path,
  status:lastPulledFromChannelTimestamp::TIMESTAMP_NTZ AS last_pulled_from_channel,
  status:notificationChannelName::STRING AS notification_channel_arn,
  status:channelErrorMessage::STRING AS channel_error_message,
  status:channelErrorTimestamp::TIMESTAMP_NTZ AS channel_error_timestamp
FROM pipe_diag;

-- 2. Correlate Real-Time Pipe Status with Ingestion History (Last 24 Hours)
SELECT
  PIPE_NAME,
  TABLE_NAME,
  STAGE_LOCATION,
  FILE_NAME,
  FILE_SIZE,
  ROW_COUNT,
  ROW_PARSED,
  ERROR_COUNT,
  ERROR_MESSAGE,
  STATUS,
  FIRST_ERROR_COLUMN_NAME,
  FIRST_ERROR_LINE_NUMBER,
  LAST_LOAD_TIME
FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
  TABLE_NAME => 'RAW_DB.INGEST_SCHEMA.EVENTS_RAW',
  START_TIME => DATEADD(hours, -24, CURRENT_TIMESTAMP())
))
ORDER BY LAST_LOAD_TIME DESC;

-- 3. Account-Level Snowpipe Hourly Credit & Byte Ingestion Tracking
SELECT
  START_TIME,
  END_TIME,
  PIPE_NAME,
  CREDITS_USED,
  BYTES_INSERTED,
  FILES_INSERTED
FROM SNOWFLAKE.ACCOUNT_USAGE.PIPE_USAGE_HISTORY
WHERE START_TIME >= DATEADD(days, -7, CURRENT_TIMESTAMP())
ORDER BY START_TIME DESC;

-- 4. Ingestion Backlog & Latency SLA Detector
WITH recent_loads AS (
  SELECT
    FILE_NAME,
    ROW_COUNT,
    LAST_LOAD_TIME,
    DATEDIFF('minute', LAST_LOAD_TIME, CURRENT_TIMESTAMP()) AS minutes_since_last_load
  FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
    TABLE_NAME => 'RAW_DB.INGEST_SCHEMA.EVENTS_RAW',
    START_TIME => DATEADD(hours, -2, CURRENT_TIMESTAMP())
  ))
)
SELECT
  COUNT(*) AS loaded_files_count,
  SUM(ROW_COUNT) AS total_rows_loaded,
  MAX(LAST_LOAD_TIME) AS latest_load_timestamp,
  MIN(minutes_since_last_load) AS latency_minutes
FROM recent_loads;
