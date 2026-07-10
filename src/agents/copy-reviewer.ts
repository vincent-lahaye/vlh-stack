/**
 * Copy Reviewer Agent
 *
 * Copy & prose reviewer who hunts AI-slop, heavy/awkward phrasing,
 * redundancy, and bloat across any human-facing copy.
 */

import type { AgentConfig, AgentPromptMetadata } from './types.js';
import { loadAgentPrompt } from './utils.js';

export const COPY_REVIEWER_PROMPT_METADATA: AgentPromptMetadata = {
  category: 'specialist',
  cost: 'FREE',
  promptAlias: 'copy-reviewer',
  triggers: [
    {
      domain: 'Copy review',
      trigger: 'Marketing copy, UI strings, docs prose, README wording',
    },
  ],
  useWhen: [
    'Reviewing marketing or landing-page copy',
    'Checking UI strings for AI-slop or awkward phrasing',
    'Tightening redundant or bloated prose',
    'Auditing docs wording for clarity and concision',
  ],
  avoidWhen: [
    'Code implementation tasks',
    'Bug fixes',
    'Translation tasks (use translator-fr)',
  ],
};

export const copyReviewerAgent: AgentConfig = {
  name: 'copy-reviewer',
  description: `Copy & prose reviewer — hunts AI-slop, heavy/awkward phrasing, redundancy, bloat across any human-facing copy.`,
  prompt: loadAgentPrompt('copy-reviewer'),
  model: 'sonnet',
  defaultModel: 'sonnet',
  metadata: COPY_REVIEWER_PROMPT_METADATA,
};
