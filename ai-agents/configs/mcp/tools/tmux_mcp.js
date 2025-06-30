#!/usr/bin/env node

// TMux MCP Server for AI Organization System
// Provides tmux session control capabilities

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

const server = new Server(
  {
    name: 'tmux-integration',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Tool definitions
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: 'tmux_send_command',
        description: 'Send command to specific tmux pane',
        inputSchema: {
          type: 'object',
          properties: {
            session: { type: 'string', description: 'Tmux session name' },
            pane: { type: 'string', description: 'Pane identifier (e.g., 0.1)' },
            command: { type: 'string', description: 'Command to send' },
          },
          required: ['session', 'pane', 'command'],
        },
      },
      {
        name: 'tmux_get_pane_content',
        description: 'Get content from tmux pane',
        inputSchema: {
          type: 'object',
          properties: {
            session: { type: 'string', description: 'Tmux session name' },
            pane: { type: 'string', description: 'Pane identifier' },
          },
          required: ['session', 'pane'],
        },
      },
    ],
  };
});

// Tool execution
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case 'tmux_send_command': {
        const { session, pane, command } = args;
        const tmuxCommand = `tmux send-keys -t ${session}:${pane} '${command}' C-m`;
        await execAsync(tmuxCommand);
        return {
          content: [{ type: 'text', text: `Command sent to ${session}:${pane}` }],
        };
      }

      case 'tmux_get_pane_content': {
        const { session, pane } = args;
        const tmuxCommand = `tmux capture-pane -t ${session}:${pane} -p`;
        const { stdout } = await execAsync(tmuxCommand);
        return {
          content: [{ type: 'text', text: stdout }],
        };
      }

      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (error) {
    return {
      content: [{ type: 'text', text: `Error: ${error.message}` }],
      isError: true,
    };
  }
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('TMux MCP Server running...');
}

main().catch(console.error);