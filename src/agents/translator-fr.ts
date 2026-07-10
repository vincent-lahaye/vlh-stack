/**
 * Translator (FR) Agent
 *
 * Professional English→French translator for product copy and docs.
 */

import type { AgentConfig, AgentPromptMetadata } from './types.js';
import { loadAgentPrompt } from './utils.js';

export const TRANSLATOR_FR_PROMPT_METADATA: AgentPromptMetadata = {
  category: 'specialist',
  cost: 'FREE',
  promptAlias: 'translator-fr',
  triggers: [
    {
      domain: 'Translation',
      trigger: 'English→French product copy, UI strings, docs',
    },
  ],
  useWhen: [
    'Translating product copy from English to French',
    'Localizing UI strings to French',
    'Translating documentation to French',
    'Ensuring FR/EN parity of user-facing copy',
  ],
  avoidWhen: [
    'Code implementation tasks',
    'Bug fixes',
    'Copy review in a single language (use copy-reviewer)',
  ],
};

export const translatorFrAgent: AgentConfig = {
  name: 'translator-fr',
  description: `Professional English→French translator for product copy and docs.`,
  prompt: loadAgentPrompt('translator-fr'),
  model: 'sonnet',
  defaultModel: 'sonnet',
  metadata: TRANSLATOR_FR_PROMPT_METADATA,
};
