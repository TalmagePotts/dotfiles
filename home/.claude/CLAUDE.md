**Language**: English
**Interaction With User**: Approach me on the same level, assuming I am a developer that seeks the highest quality for my projects. However, whenever there is something I need to do in the code or on the internet to make something work well, approach me as an absolute beginner with step by step prompts on what to do exactly.

**Sub-agents**: ALWAYS use Sonnet when you use sub-agents.

## App Design:
- **Assume keyboard-first workflow**: Every action should have a keyboard shortcut or Enter-to-submit
- **Minimize clicks**: Use icons, inline actions, auto-focus to reduce user effort
- **Always validate**: Don't let bad data in; show clear feedback
- **Confirm destructive actions**: Delete, overwrite, etc. need confirmation
- **Smart defaults**: Auto-focus, clear on focus, remember settings
- **Debug-friendly**: Add logging for state changes and user interactions

## Framework-Specific Notes
- Using Tauri: Use Tauri APIs (dialog, clipboard, etc.) not browser APIs
- Test all interactive features work before saying "done"
- If something "doesn't work", immediately add debug logging and check:
  * Event handlers bound correctly
  * State updates triggering
  * API calls succeeding
- Test window behaviors (always-on-top, moveable, etc.) before confirming
- Validate all interactive features work before saying "done"

## Compact, Simple, and Beautiful UI Design:
- Prefer icons over text buttons where meaning is clear
- Use inline actions to minimize clicks
- Smart defaults: auto-focus, remember settings, clear-on-focus

## When Something "Doesn't Work"
If I say something doesn't work:
1. Add debug logging immediately (console.log state, event handlers, API responses)
2. Check event handlers are actually firing
3. Verify state updates trigger re-renders
4. Test in dev tools before responding
5. Don't guess - investigate systematically

## Testing Requirements
- For complex features, write tests FIRST (Vitest unit tests, Playwright e2e)
- Then iterate until tests pass
- Only mark feature complete when test suite is green


## Writing code
- Never ever leave something half finished. 
- Always complete any things in the code that have a TO DO Document
- Avoid hard coded values when possible.
- If you are reaching your context limit or the session limit, please stop and give a sumamry of what is done and what needs to be done next.
