-- Insert sample data for development and testing
-- This script runs after indexes are created

-- Insert sample admin user
INSERT INTO admin.users (id, email, username, password_hash, first_name, last_name, role) 
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'admin@magicain.ai',
    'admin',
    '$2a$10$7Q.XnGgSgB8.HXz7zKjdgOEPo6nxZBV.rHzLOKUx2QaHmvSzLXKZu', -- password: admin123
    'Admin',
    'User',
    'admin'
) ON CONFLICT (email) DO NOTHING;

-- Insert sample regular user
INSERT INTO admin.users (id, email, username, password_hash, first_name, last_name, role) 
VALUES (
    '00000000-0000-0000-0000-000000000002',
    'user@magicain.ai',
    'testuser',
    '$2a$10$7Q.XnGgSgB8.HXz7zKjdgOEPo6nxZBV.rHzLOKUx2QaHmvSzLXKZu', -- password: admin123
    'Test',
    'User',
    'user'
) ON CONFLICT (email) DO NOTHING;

-- Insert sample AI agents
INSERT INTO ai_agents.agents (id, name, description, model_name, system_prompt, created_by) 
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'General Assistant',
    'A helpful AI assistant for general queries and conversations',
    'gpt-4',
    'You are a helpful AI assistant. Provide accurate, helpful, and friendly responses to user queries.',
    '00000000-0000-0000-0000-000000000001'
), (
    '00000000-0000-0000-0000-000000000002',
    'Code Assistant',
    'Specialized AI assistant for programming and development tasks',
    'gpt-4',
    'You are an expert programming assistant. Help users with coding questions, debugging, and software development best practices.',
    '00000000-0000-0000-0000-000000000001'
), (
    '00000000-0000-0000-0000-000000000003',
    'Data Analyst',
    'AI assistant specialized in data analysis and visualization',
    'gpt-4',
    'You are a data analysis expert. Help users understand their data, create visualizations, and derive insights.',
    '00000000-0000-0000-0000-000000000001'
) ON CONFLICT (id) DO NOTHING;

-- Insert sample chat session
INSERT INTO chat.sessions (id, user_id, agent_id, title) 
VALUES (
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000001',
    'Welcome Chat'
) ON CONFLICT (id) DO NOTHING;

-- Insert sample chat messages
INSERT INTO chat.messages (session_id, role, content) 
VALUES 
    ('00000000-0000-0000-0000-000000000001', 'user', 'Hello! Can you help me get started with this AI system?'),
    ('00000000-0000-0000-0000-000000000001', 'assistant', 'Hello! I''d be happy to help you get started with the Magicain AI system. This platform provides various AI agents for different tasks. What would you like to know about?'),
    ('00000000-0000-0000-0000-000000000001', 'user', 'What types of AI agents are available?'),
    ('00000000-0000-0000-0000-000000000001', 'assistant', 'We have several specialized AI agents available: a General Assistant for everyday queries, a Code Assistant for programming tasks, and a Data Analyst for data-related work. Each agent is optimized for its specific domain. Would you like to try working with any of these agents?')
ON CONFLICT (id) DO NOTHING;

-- Insert sample knowledge base document
INSERT INTO ai_agents.documents (id, title, content, agent_id, metadata) 
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'AI System Overview',
    'The Magicain AI system is a comprehensive platform for AI-powered conversations and assistance. It includes multiple specialized agents, vector search capabilities, and comprehensive monitoring. The system supports real-time chat, document analysis, and intelligent responses based on context and user needs.',
    '00000000-0000-0000-0000-000000000001',
    '{"category": "documentation", "tags": ["overview", "introduction"]}'
) ON CONFLICT (id) DO NOTHING;

-- Insert sample execution log
INSERT INTO ai_agents.execution_logs (agent_id, session_id, input_tokens, output_tokens, total_tokens, execution_time_ms, cost_usd, metadata) 
VALUES (
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    25,
    150,
    175,
    1250,
    0.0035,
    '{"model": "gpt-4", "temperature": 0.7}'
) ON CONFLICT (id) DO NOTHING;

-- Insert sample metrics
INSERT INTO monitoring.metrics (metric_name, metric_value, metric_type, labels) 
VALUES 
    ('ai_requests_total', 1, 'counter', '{"agent": "general_assistant", "status": "success"}'),
    ('ai_response_time_ms', 1250, 'histogram', '{"agent": "general_assistant"}'),
    ('active_sessions', 1, 'gauge', '{}'),
    ('database_connections', 5, 'gauge', '{"pool": "main"}')
ON CONFLICT (id) DO NOTHING;