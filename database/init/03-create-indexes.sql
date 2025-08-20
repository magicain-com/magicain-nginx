-- Create indexes for optimal query performance
-- This script runs after tables are created

-- Users indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON admin.users(email);
CREATE INDEX IF NOT EXISTS idx_users_username ON admin.users(username);
CREATE INDEX IF NOT EXISTS idx_users_role ON admin.users(role);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON admin.users(is_active);

-- Agents indexes
CREATE INDEX IF NOT EXISTS idx_agents_name ON ai_agents.agents(name);
CREATE INDEX IF NOT EXISTS idx_agents_model_name ON ai_agents.agents(model_name);
CREATE INDEX IF NOT EXISTS idx_agents_is_active ON ai_agents.agents(is_active);
CREATE INDEX IF NOT EXISTS idx_agents_created_by ON ai_agents.agents(created_by);

-- Chat sessions indexes
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON chat.sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_agent_id ON chat.sessions(agent_id);
CREATE INDEX IF NOT EXISTS idx_sessions_is_active ON chat.sessions(is_active);
CREATE INDEX IF NOT EXISTS idx_sessions_created_at ON chat.sessions(created_at);

-- Chat messages indexes
CREATE INDEX IF NOT EXISTS idx_messages_session_id ON chat.messages(session_id);
CREATE INDEX IF NOT EXISTS idx_messages_role ON chat.messages(role);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON chat.messages(created_at);

-- Vector embeddings indexes
-- HNSW index for fast vector similarity search
CREATE INDEX IF NOT EXISTS idx_embeddings_vector_hnsw 
ON ai_agents.embeddings 
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- IVFFlat index as alternative for large datasets
-- CREATE INDEX IF NOT EXISTS idx_embeddings_vector_ivfflat 
-- ON ai_agents.embeddings 
-- USING ivfflat (embedding vector_cosine_ops)
-- WITH (lists = 100);

CREATE INDEX IF NOT EXISTS idx_embeddings_source_type ON ai_agents.embeddings(source_type);
CREATE INDEX IF NOT EXISTS idx_embeddings_source_id ON ai_agents.embeddings(source_id);
CREATE INDEX IF NOT EXISTS idx_embeddings_metadata_gin ON ai_agents.embeddings USING gin(metadata);

-- Documents indexes
CREATE INDEX IF NOT EXISTS idx_documents_title ON ai_agents.documents(title);
CREATE INDEX IF NOT EXISTS idx_documents_agent_id ON ai_agents.documents(agent_id);
CREATE INDEX IF NOT EXISTS idx_documents_mime_type ON ai_agents.documents(mime_type);
CREATE INDEX IF NOT EXISTS idx_documents_created_at ON ai_agents.documents(created_at);

-- Full-text search index for document content
CREATE INDEX IF NOT EXISTS idx_documents_content_fulltext 
ON ai_agents.documents 
USING gin(to_tsvector('english', content));

-- Execution logs indexes
CREATE INDEX IF NOT EXISTS idx_execution_logs_agent_id ON ai_agents.execution_logs(agent_id);
CREATE INDEX IF NOT EXISTS idx_execution_logs_session_id ON ai_agents.execution_logs(session_id);
CREATE INDEX IF NOT EXISTS idx_execution_logs_trace_id ON ai_agents.execution_logs(trace_id);
CREATE INDEX IF NOT EXISTS idx_execution_logs_status ON ai_agents.execution_logs(status);
CREATE INDEX IF NOT EXISTS idx_execution_logs_created_at ON ai_agents.execution_logs(created_at);

-- Monitoring metrics indexes
CREATE INDEX IF NOT EXISTS idx_metrics_name ON monitoring.metrics(metric_name);
CREATE INDEX IF NOT EXISTS idx_metrics_type ON monitoring.metrics(metric_type);
CREATE INDEX IF NOT EXISTS idx_metrics_timestamp ON monitoring.metrics(timestamp);
CREATE INDEX IF NOT EXISTS idx_metrics_labels_gin ON monitoring.metrics USING gin(labels);

-- API usage indexes
CREATE INDEX IF NOT EXISTS idx_api_usage_user_id ON monitoring.api_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_api_usage_endpoint ON monitoring.api_usage(endpoint);
CREATE INDEX IF NOT EXISTS idx_api_usage_status_code ON monitoring.api_usage(status_code);
CREATE INDEX IF NOT EXISTS idx_api_usage_created_at ON monitoring.api_usage(created_at);
CREATE INDEX IF NOT EXISTS idx_api_usage_ip_address ON monitoring.api_usage(ip_address);

-- Composite indexes for common query patterns
CREATE INDEX IF NOT EXISTS idx_messages_session_created 
ON chat.messages(session_id, created_at);

CREATE INDEX IF NOT EXISTS idx_execution_logs_agent_created 
ON ai_agents.execution_logs(agent_id, created_at);

CREATE INDEX IF NOT EXISTS idx_api_usage_user_created 
ON monitoring.api_usage(user_id, created_at);