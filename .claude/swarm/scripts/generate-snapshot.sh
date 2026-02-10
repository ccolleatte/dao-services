#!/usr/bin/env bash
# =============================================================================
# generate-snapshot.sh — Genere le snapshot codebase pour le Lean Swarm v3.2
#
# Usage : bash .claude/swarm/scripts/generate-snapshot.sh [project_root]
# Par defaut, project_root = repertoire courant
# =============================================================================

set -euo pipefail

PROJECT_ROOT="${1:-.}"
SNAPSHOT_DIR="$PROJECT_ROOT/.claude/swarm/snapshots"
SNAPSHOT_FILE="$SNAPSHOT_DIR/codebase.md"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

echo "[SWARM] Generation du snapshot codebase..."
echo "[SWARM] Projet : $PROJECT_ROOT"

# --- Detection de l'ecosysteme ---

detect_ecosystem() {
    if [ -f "$PROJECT_ROOT/package.json" ]; then
        if [ -f "$PROJECT_ROOT/tsconfig.json" ]; then echo "typescript"
        else echo "javascript"; fi
    elif [ -f "$PROJECT_ROOT/requirements.txt" ] || [ -f "$PROJECT_ROOT/pyproject.toml" ]; then
        echo "python"
    elif [ -f "$PROJECT_ROOT/Cargo.toml" ]; then echo "rust"
    elif [ -f "$PROJECT_ROOT/go.mod" ]; then echo "go"
    else echo "unknown"; fi
}

ECOSYSTEM=$(detect_ecosystem)
echo "[SWARM] Ecosysteme : $ECOSYSTEM"

# --- Extensions par ecosysteme ---

get_extensions() {
    case "$ECOSYSTEM" in
        typescript)  echo "ts tsx js jsx" ;;
        javascript)  echo "js jsx mjs cjs" ;;
        python)      echo "py" ;;
        rust)        echo "rs" ;;
        go)          echo "go" ;;
        *)           echo "ts tsx js jsx py rs go" ;;
    esac
}

EXTENSIONS=$(get_extensions)

FIND_PATTERN=""
for ext in $EXTENSIONS; do
    [ -n "$FIND_PATTERN" ] && FIND_PATTERN="$FIND_PATTERN -o"
    FIND_PATTERN="$FIND_PATTERN -name *.$ext"
done

EXCLUDE_DIRS="node_modules .git dist build .next __pycache__ .venv venv target .claude coverage"
EXCLUDE_PATTERN=""
for dir in $EXCLUDE_DIRS; do
    EXCLUDE_PATTERN="$EXCLUDE_PATTERN -not -path */$dir/*"
done

# --- 1. Structure (compresse, pipe-delimited) ---

echo "[SWARM] Analyse de la structure..."

generate_structure() {
    find "$PROJECT_ROOT" -maxdepth 3 -type d $EXCLUDE_PATTERN \
        -not -path "$PROJECT_ROOT/.claude/*" -not -path "$PROJECT_ROOT" \
        2>/dev/null | sort | while read -r dir; do
        local count=0
        for ext in $EXTENSIONS; do
            local c=$(find "$dir" -maxdepth 1 -name "*.$ext" 2>/dev/null | wc -l)
            count=$((count + c))
        done
        if [ "$count" -gt 0 ]; then
            local relpath="${dir#$PROJECT_ROOT/}"
            local files=""
            for ext in $EXTENSIONS; do
                for f in "$dir"/*.$ext 2>/dev/null; do
                    [ -f "$f" ] && files="$files$(basename "$f"),"
                done
            done
            files="${files%,}"
            echo "$relpath:{$files}"
        fi
    done
}

STRUCTURE=$(generate_structure)

# --- 2. Detection des patterns ---

echo "[SWARM] Detection des patterns..."

detect_patterns() {
    local src_files
    src_files=$(find "$PROJECT_ROOT" $EXCLUDE_PATTERN \( $FIND_PATTERN \) -type f 2>/dev/null)
    [ -z "$src_files" ] && { echo "aucun-fichier-source|0|N/A"; return; }

    local repo_count=$(echo "$src_files" | xargs grep -li "Repository\|Repo" 2>/dev/null | wc -l)
    [ "$repo_count" -gt 0 ] && echo "repository-pattern|$repo_count|$(echo "$src_files" | xargs grep -li "Repository\|Repo" 2>/dev/null | head -3 | tr '\n' ',')"

    local factory_count=$(echo "$src_files" | xargs grep -li "Factory\|create[A-Z]" 2>/dev/null | wc -l)
    [ "$factory_count" -gt 0 ] && echo "factory-pattern|$factory_count|$(echo "$src_files" | xargs grep -li "Factory\|create[A-Z]" 2>/dev/null | head -3 | tr '\n' ',')"

    local mw_count=$(echo "$src_files" | xargs grep -li "middleware\|Middleware" 2>/dev/null | wc -l)
    [ "$mw_count" -gt 0 ] && echo "middleware-chain|$mw_count|$(echo "$src_files" | xargs grep -li "middleware" 2>/dev/null | head -3 | tr '\n' ',')"

    local result_count=$(echo "$src_files" | xargs grep -li "Result<\|Either<\|Result\[" 2>/dev/null | wc -l)
    [ "$result_count" -gt 0 ] && echo "error-as-value|$result_count|$(echo "$src_files" | xargs grep -li "Result<\|Either<" 2>/dev/null | head -3 | tr '\n' ',')"

    local di_count=$(echo "$src_files" | xargs grep -li "@Inject\|@Injectable\|inject(" 2>/dev/null | wc -l)
    [ "$di_count" -gt 0 ] && echo "dependency-injection|$di_count|$(echo "$src_files" | xargs grep -li "@Inject\|inject(" 2>/dev/null | head -3 | tr '\n' ',')"

    local hooks_count=$(echo "$src_files" | xargs grep -li "useState\|useEffect\|useCallback" 2>/dev/null | wc -l)
    [ "$hooks_count" -gt 0 ] && echo "react-hooks|$hooks_count|$(echo "$src_files" | xargs grep -li "useState\|useEffect" 2>/dev/null | head -3 | tr '\n' ',')"

    local async_count=$(echo "$src_files" | xargs grep -c "async " 2>/dev/null | awk -F: '{sum+=$2} END{print sum}')
    [ "$async_count" -gt 5 ] && echo "async-await-dominant|$async_count|throughout codebase"
}

PATTERNS=$(detect_patterns)

# --- 3. Conventions ---

echo "[SWARM] Detection des conventions..."

detect_conventions() {
    local src_files
    src_files=$(find "$PROJECT_ROOT" $EXCLUDE_PATTERN \( $FIND_PATTERN \) -type f 2>/dev/null)

    local kebab=$(echo "$src_files" | grep -c "\-" 2>/dev/null || echo 0)
    local camel=$(echo "$src_files" | grep -cE "[a-z][A-Z]" 2>/dev/null || echo 0)
    local pascal=$(echo "$src_files" | grep -cE "/[A-Z][a-z]" 2>/dev/null || echo 0)
    local file_naming="mixed"
    [ "$kebab" -gt "$camel" ] && [ "$kebab" -gt "$pascal" ] && file_naming="kebab-case"
    [ "$camel" -gt "$kebab" ] && [ "$camel" -gt "$pascal" ] && file_naming="camelCase"
    [ "$pascal" -gt "$kebab" ] && [ "$pascal" -gt "$camel" ] && file_naming="PascalCase"
    echo "files: $file_naming"

    if [ -d "$PROJECT_ROOT/tests" ] || [ -d "$PROJECT_ROOT/test" ]; then
        echo "test_location: dedicated directory"
    elif find "$PROJECT_ROOT" -name "*.test.*" -o -name "*.spec.*" 2>/dev/null | head -1 | grep -q .; then
        echo "test_location: co-located"
    elif find "$PROJECT_ROOT" -path "*__tests__*" 2>/dev/null | head -1 | grep -q .; then
        echo "test_location: __tests__ directories"
    else
        echo "test_location: not detected"
    fi

    if find "$PROJECT_ROOT" -name "*.test.*" 2>/dev/null | head -1 | grep -q .; then
        echo "test_naming: *.test.*"
    elif find "$PROJECT_ROOT" -name "*.spec.*" 2>/dev/null | head -1 | grep -q .; then
        echo "test_naming: *.spec.*"
    elif find "$PROJECT_ROOT" -name "test_*" 2>/dev/null | head -1 | grep -q .; then
        echo "test_naming: test_*"
    else
        echo "test_naming: not detected"
    fi

    if [ -n "$src_files" ]; then
        local try_catch=$(echo "$src_files" | xargs grep -c "try {" 2>/dev/null | awk -F: '{sum+=$2} END{print sum+0}')
        local result_type=$(echo "$src_files" | xargs grep -c "Result<\|Result\[" 2>/dev/null | awk -F: '{sum+=$2} END{print sum+0}')
        if [ "$result_type" -gt "$try_catch" ]; then echo "error_handling: Result type"
        elif [ "$try_catch" -gt 0 ]; then echo "error_handling: try-catch"
        else echo "error_handling: not detected"; fi
    fi
}

CONVENTIONS=$(detect_conventions)

# --- 4. Metriques par zone ---

echo "[SWARM] Calcul des metriques..."

compute_metrics() {
    local src_dir="$PROJECT_ROOT/src"
    [ ! -d "$src_dir" ] && src_dir="$PROJECT_ROOT/app"
    [ ! -d "$src_dir" ] && src_dir="$PROJECT_ROOT/lib"
    [ ! -d "$src_dir" ] && src_dir="$PROJECT_ROOT"

    find "$src_dir" -maxdepth 1 -type d 2>/dev/null | while read -r zone; do
        [ "$zone" = "$src_dir" ] && continue
        local relpath="${zone#$PROJECT_ROOT/}"
        local complexity=0 file_count=0

        for ext in $EXTENSIONS; do
            for f in $(find "$zone" -name "*.$ext" $EXCLUDE_PATTERN -type f 2>/dev/null); do
                local fc=$(grep -cE "if |else |for |while |switch |catch |elif |except " "$f" 2>/dev/null || echo 0)
                complexity=$((complexity + fc))
                file_count=$((file_count + 1))
            done
        done

        if [ "$file_count" -gt 0 ]; then
            local avg=$(awk "BEGIN {printf \"%.1f\", $complexity / $file_count}")
            local imports=$(find "$zone" -type f $EXCLUDE_PATTERN 2>/dev/null | xargs grep -c "import\|require\|from " 2>/dev/null | awk -F: '{sum+=$2} END{print sum+0}')
            local coupling="low"
            [ "$imports" -gt 50 ] && coupling="moderate"
            [ "$imports" -gt 100 ] && coupling="high"
            local test_files=$(find "$zone" \( -name "*.test.*" -o -name "*.spec.*" -o -name "test_*" \) -type f 2>/dev/null | wc -l)
            local cov_pct=$(awk "BEGIN {printf \"%.0f\", ($test_files / $file_count) * 100}")
            echo "$relpath/|avg_complexity=$avg|coupling=$coupling|test_ratio=${cov_pct}%"
        fi
    done
}

METRICS=$(compute_metrics)

# --- 5. Dependances ---

echo "[SWARM] Analyse des dependances..."

analyze_deps() {
    if [ -f "$PROJECT_ROOT/package.json" ] && command -v jq &>/dev/null; then
        jq -r '.dependencies // {} | to_entries[] | "\(.key)|\(.value)"' "$PROJECT_ROOT/package.json" 2>/dev/null
    elif [ -f "$PROJECT_ROOT/requirements.txt" ]; then
        grep -v "^#\|^$" "$PROJECT_ROOT/requirements.txt" 2>/dev/null | head -20
    else
        echo "# Aucun fichier de dependances detecte"
    fi
}

DEPS=$(analyze_deps)

# --- 6. Code mort ---

echo "[SWARM] Detection de code mort..."

detect_dead_code() {
    local src_files
    src_files=$(find "$PROJECT_ROOT" $EXCLUDE_PATTERN \( $FIND_PATTERN \) -type f 2>/dev/null)
    [ -z "$src_files" ] && return

    for ext in $EXTENSIONS; do
        find "$PROJECT_ROOT" $EXCLUDE_PATTERN -name "*.$ext" -type f 2>/dev/null | while read -r f; do
            local basename=$(basename "$f" ".$ext")
            local relpath="${f#$PROJECT_ROOT/}"
            local import_count=$(echo "$src_files" | xargs grep -l "$basename" 2>/dev/null | grep -v "$f" | wc -l)
            if [ "$import_count" -eq 0 ]; then
                case "$basename" in
                    index|main|app|server|config|setup|__init__) continue ;;
                    *) echo "$relpath|aucun import detecte (possible faux positif)" ;;
                esac
            fi
        done
    done | head -20
}

DEAD_CODE=$(detect_dead_code)

# --- Comptage ---

TOTAL_FILES=$(find "$PROJECT_ROOT" $EXCLUDE_PATTERN \( $FIND_PATTERN \) -type f 2>/dev/null | wc -l)

# --- Assemblage ---

echo "[SWARM] Assemblage du snapshot..."

cat > "$SNAPSHOT_FILE" << SNAPSHOT
# Snapshot Codebase

> Fichier genere automatiquement. Ne pas modifier manuellement.

## Metadata
\`\`\`yaml
generated_at: "$TIMESTAMP"
staleness_threshold: "48h"
project_root: "$PROJECT_ROOT"
ecosystem: "$ECOSYSTEM"
analyzed_files: $TOTAL_FILES
\`\`\`

## Structure du Projet
\`\`\`
$STRUCTURE
\`\`\`

## Patterns Detectes
\`\`\`
$PATTERNS
\`\`\`

## Conventions en Vigueur
\`\`\`yaml
$CONVENTIONS
\`\`\`

## Metriques par Zone
\`\`\`
$METRICS
\`\`\`

## Zones de Fragilite
\`\`\`
$(echo "$METRICS" | awk -F'|' '{
    split($2, a, "=");
    complexity = a[2]+0;
    if (complexity > 10) print $1"|complexite elevee ("$2")|impact analysis recommandee"
}')
\`\`\`

## Dependances Cles
\`\`\`
$DEPS
\`\`\`

## Code Mort Detecte
\`\`\`
$DEAD_CODE
\`\`\`
SNAPSHOT

echo "[SWARM] Snapshot genere : $SNAPSHOT_FILE ($TOTAL_FILES fichiers analyses)"
