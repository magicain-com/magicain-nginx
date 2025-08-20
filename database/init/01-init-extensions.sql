-- Enable required extensions for the magicain database
-- This script runs first during database initialization

-- Enable pgvector extension for vector similarity search
CREATE EXTENSION IF NOT EXISTS vector;

-- Enable uuid-ossp for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pg_trgm for text similarity search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Enable btree_gin for advanced indexing
CREATE EXTENSION IF NOT EXISTS btree_gin;

-- Create schemas for different components
CREATE SCHEMA IF NOT EXISTS ai_agents;
CREATE SCHEMA IF NOT EXISTS chat;
CREATE SCHEMA IF NOT EXISTS admin;
CREATE SCHEMA IF NOT EXISTS monitoring;

-- Grant permissions to magicain user
GRANT USAGE ON SCHEMA ai_agents TO magicain;
GRANT USAGE ON SCHEMA chat TO magicain;
GRANT USAGE ON SCHEMA admin TO magicain;
GRANT USAGE ON SCHEMA monitoring TO magicain;

GRANT CREATE ON SCHEMA ai_agents TO magicain;
GRANT CREATE ON SCHEMA chat TO magicain;
GRANT CREATE ON SCHEMA admin TO magicain;
GRANT CREATE ON SCHEMA monitoring TO magicain;