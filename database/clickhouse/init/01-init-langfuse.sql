-- ClickHouse initialization for Langfuse analytics
-- This script sets up the database and user for Langfuse

-- Create the langfuse database
CREATE DATABASE IF NOT EXISTS langfuse;

-- Create user (if not using environment variables)
-- CREATE USER IF NOT EXISTS langfuse IDENTIFIED BY 'langfuse123';

-- Grant permissions to the langfuse user
-- GRANT ALL ON langfuse.* TO langfuse;

-- Switch to langfuse database
USE langfuse;

-- Create tables for Langfuse analytics (these will be created by Langfuse automatically)
-- But we can pre-optimize some settings

-- Set up optimal settings for analytics workload
SET max_memory_usage = 10000000000;
SET max_bytes_before_external_group_by = 20000000000;