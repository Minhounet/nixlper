#!/usr/bin/env bash
# PreToolUse(Bash): before any `git commit`, run the mechanical definition-of-done checks and block the commit
# (exit 2, reasons on stderr) if they fail; otherwise remind Claude of the judgment items no script can check.
input="$(cat)"
cmd="$(jq -r '.tool_input.command // empty' <<< "${input}" 2>/dev/null || printf '%s' "${input}")"
# Only a real `git [opts] commit` at the start of a command segment — not the words inside a heredoc or grep.
sed 's/&&/\n/g; s/||/\n/g; s/;/\n/g; s/|/\n/g' <<< "${cmd}" \
  | grep -qE '^[[:space:]]*git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+commit([[:space:]]|$)' \
  || exit 0

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
out="$( { bash scripts/check-doc-sync.sh && bash scripts/check-feature-completeness.sh --changelog-base origin/main; } 2>&1 )"
if [[ $? -ne 0 ]]; then
  printf 'Commit blocked — fix these first (staged or not, the working tree is what is checked):\n%s\n' "${out}" >&2
  exit 2
fi

cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"Mechanical checks passed (doc-sync, tests wired, config templates, FR/EN pairs, CHANGELOG). Still on you: 1) bug sweep of every function you touched (special chars, missing files, runs twice, older callers); 2) tests for the changed behaviour, run and passing; 3) help/EN/FR prose actually describes the new behaviour; 4) KNOWN_ISSUES.md / INTERNALS.md updated if relevant."}}
JSON
