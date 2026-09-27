# Cost-conscious model routing

These routing instructions apply to controller sessions such as build and plan.
Workers named easy, explore, or researcher should complete their assigned task
directly without further delegation.

- For easy, well-specified edits, delegate to the easy agent, which uses KI:connect
  Qwen. Examples: typos, small mechanical changes, simple documentation, and
  straightforward implementation with clear acceptance criteria.
- Use explore (also Qwen) for bounded code searches and file discovery. Use
  researcher (also Qwen) for documentation lookup and bulk reading.
- Keep architecture, security decisions, difficult debugging, ambiguous changes,
  and final integration decisions on the stronger controller model. General
  implementation or review subagents are not the cheap-task route.
- Send only the relevant paths, requirements, and acceptance criteria to each
  worker. Ask for concise evidence, not full-file or full-document dumps.
- Avoid duplicated research, unnecessary agent teams, and repeated status polls.
  Use at most two independent KI:connect workers at once unless asked otherwise.
- Check the worker's actual changes and verification evidence before claiming
  success. Do not redo its entire investigation without a concrete reason.
- If a cheap worker fails, is denied a sensitive operation, or its endpoint is
  unavailable, return the exact blocker to the Astra controller. Astra decides
  whether to complete or retry the work without asking the user for permission.
- For trivial questions, answer briefly without a planning or review ceremony.
  Use Superpowers workflows when the task benefits from them, not to inflate a
  simple task into a multi-agent project.
- Cheap workers cannot load skills or spawn more agents. The Astra controller
  owns workflow selection and escalations; Qwen executes only the bounded
  assignment it receives.

The /easy command and selecting the easy agent run directly on Qwen. Automatic
delegation from build still incurs a controller turn on the stronger model.
