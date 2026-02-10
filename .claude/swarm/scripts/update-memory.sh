#!/usr/bin/env bash
# =============================================================================
# update-memory.sh — Met a jour la memoire retrospective apres une tache
#
# Usage : bash .claude/swarm/scripts/update-memory.sh
#
# Peut etre invoque manuellement ou par Claude Code apres une tache.
# Claude Code peut aussi editer directement retrospective.md.
# =============================================================================

set -euo pipefail

MEMORY_FILE=".claude/swarm/memory/retrospective.md"
TIMESTAMP=$(date -u +"%Y-%m-%d")

if [ ! -f "$MEMORY_FILE" ]; then
    echo "ERREUR: Fichier memoire non trouve : $MEMORY_FILE"
    exit 1
fi

echo "Mise a jour de la memoire retrospective"
echo "---"

read -p "Resume de la demande (1 ligne) : " REQUEST
read -p "Vrai probleme identifie : " REAL_PROBLEM
read -p "Lentilles invoquees (ex: analytical>contextual>sandbox) : " PATH_TAKEN
read -p "Decision (no_action|config|reuse|modify|create) : " DECISION
read -p "Lignes de code produites (0 si pas de code) : " CODE_PRODUCED
read -p "Resultat (success|partial|failure|reverted) : " OUTCOME
read -p "Etait-ce optimal retrospectivement ? (yes|no) : " WAS_OPTIMAL
read -p "Lecon apprise (1 ligne) : " LESSON

ENTRY="# ---
# date: $TIMESTAMP
# request: $REQUEST
# real_problem: $REAL_PROBLEM
# path: $PATH_TAKEN
# decision: $DECISION
# code_produced: $CODE_PRODUCED lignes
# outcome: $OUTCOME
# was_optimal: $WAS_OPTIMAL
# lesson: $LESSON
# ---"

echo "" >> "$MEMORY_FILE"
echo "$ENTRY" >> "$MEMORY_FILE"

TOTAL=$(grep -c "^# date:" "$MEMORY_FILE" 2>/dev/null || echo 0)
sed -i "s/total_trajectories: .*/total_trajectories: $TOTAL/" "$MEMORY_FILE"
sed -i "s/last_updated: .*/last_updated: \"${TIMESTAMP}T00:00:00Z\"/" "$MEMORY_FILE"

if [ "$TOTAL" -ge 5 ]; then
    echo ""
    echo "Mise a jour des metriques de calibration..."

    NO_ACTION=$(grep -c "decision: no_action" "$MEMORY_FILE" 2>/dev/null || echo 0)
    ABANDON_RATE=$(awk "BEGIN {printf \"%.0f\", ($NO_ACTION / $TOTAL) * 100}")
    sed -i "s/abandonment_rate: .*/abandonment_rate: ${ABANDON_RATE}%/" "$MEMORY_FILE"

    NO_CODE=$(grep "code_produced: 0" "$MEMORY_FILE" 2>/dev/null | wc -l || echo 0)
    NO_CODE_RATE=$(awk "BEGIN {printf \"%.0f\", ($NO_CODE / $TOTAL) * 100}")
    sed -i "s/no_code_resolution_rate: .*/no_code_resolution_rate: ${NO_CODE_RATE}%/" "$MEMORY_FILE"

    echo ""
    [ "$ABANDON_RATE" -lt 5 ] && echo "ALERTE: abandonment_rate < 5% — Le Noyau dit oui trop souvent"
    [ "$NO_CODE_RATE" -lt 10 ] && echo "ALERTE: no_code_resolution_rate < 10% — On code trop"
fi

echo ""
echo "Trajectoire #$TOTAL enregistree."
