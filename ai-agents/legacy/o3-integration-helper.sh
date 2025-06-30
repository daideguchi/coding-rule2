#!/bin/bash
# 🧠 o3連携ヘルパーシステム v1.0

set -euo pipefail

# 色付きログ関数
log_info() {
    echo -e "\033[1;32m[INFO]\033[0m $1"
}

log_success() {
    echo -e "\033[1;34m[SUCCESS]\033[0m $1"
}

log_error() {
    echo -e "\033[1;31m[ERROR]\033[0m $1"
}

log_warn() {
    echo -e "\033[1;33m[WARN]\033[0m $1"
}

# 🔍 問題難易度判定
assess_problem_complexity() {
    local problem_description="$1"
    
    log_info "🔍 問題難易度判定開始"
    
    # キーワードベースの難易度判定
    local high_complexity_keywords=(
        "machine learning" "AI" "neural network" "distributed system"
        "microservices" "blockchain" "kubernetes" "docker swarm"
        "real-time processing" "big data" "scalability" "performance optimization"
        "security vulnerability" "cryptography" "authentication" "authorization"
        "latest framework" "2024" "2025" "cutting-edge" "state-of-the-art"
    )
    
    local medium_complexity_keywords=(
        "architecture" "design pattern" "best practice" "integration"
        "database optimization" "API design" "testing strategy"
        "deployment" "monitoring" "logging" "error handling"
    )
    
    local complexity_score=0
    
    for keyword in "${high_complexity_keywords[@]}"; do
        if echo "$problem_description" | grep -qi "$keyword"; then
            ((complexity_score += 3))
        fi
    done
    
    for keyword in "${medium_complexity_keywords[@]}"; do
        if echo "$problem_description" | grep -qi "$keyword"; then
            ((complexity_score += 1))
        fi
    done
    
    # 難易度判定結果
    if [ $complexity_score -ge 6 ]; then
        echo "HIGH"
        log_warn "🔴 高難易度問題 - o3連携を強く推奨"
    elif [ $complexity_score -ge 3 ]; then
        echo "MEDIUM"
        log_info "🟡 中難易度問題 - o3連携を推奨"
    else
        echo "LOW"
        log_success "🟢 低難易度問題 - 通常処理で対応可能"
    fi
    
    return $complexity_score
}

# 🎯 o3リサーチクエリ生成
generate_o3_query() {
    local problem_type="$1"
    local problem_description="$2"
    local additional_context="$3"
    
    log_info "🎯 o3リサーチクエリ生成: $problem_type"
    
    local query_file="/tmp/ai-agents/o3-query-$(date +%Y%m%d-%H%M%S).md"
    mkdir -p "/tmp/ai-agents"
    
    case "$problem_type" in
        "technical")
            cat > "$query_file" << EOF
# 🔍 Technical Research Query for o3

## Problem Context
$problem_description

## Additional Context
$additional_context

## Research Request
Please research the latest best practices and solutions for this technical challenge as of 2024-2025:

### 1. Current Technology Landscape
- Latest stable versions and recent updates
- Industry adoption trends and community feedback
- Performance benchmarks and comparative analysis

### 2. Implementation Guidance
- Recommended setup and configuration approaches
- Security considerations and best practices
- Common pitfalls and avoidance strategies

### 3. Integration & Architecture
- Compatible libraries and ecosystem tools
- Architecture patterns and design principles
- Scalability and long-term maintenance considerations

### 4. Specific Solution Approach
Please provide actionable recommendations with:
- Step-by-step implementation guidance
- Code examples and configuration samples
- Testing and validation strategies
- Alternative approaches with trade-off analysis

### 5. Future Considerations
- Technology evolution and migration paths
- Emerging trends and upcoming changes
- Preparation for future requirements
EOF
            ;;
        "architecture")
            cat > "$query_file" << EOF
# 🏗️ Architecture Design Query for o3

## System Requirements
$problem_description

## Project Context
$additional_context

## Design Request
Help design a robust and scalable architecture solution:

### 1. System Analysis
- Functional requirement breakdown
- Non-functional requirements (performance, scalability, security)
- Constraints and limitation analysis

### 2. Architecture Design
- Component breakdown and responsibility allocation
- Data flow and communication patterns
- Error handling and resilience strategies
- Security architecture and threat mitigation

### 3. Technology Stack Recommendations
- Recommended technologies with detailed justifications
- Alternative approaches and comprehensive trade-offs
- Integration patterns and compatibility considerations

### 4. Implementation Strategy
- Phase-by-phase development and deployment plan
- Risk assessment and mitigation strategies
- Testing and validation approaches
- Monitoring and maintenance strategies

### 5. Scalability & Evolution
- Horizontal and vertical scaling approaches
- Future evolution and migration paths
- Performance optimization strategies

Please provide detailed architectural diagrams and implementation roadmaps.
EOF
            ;;
        "debugging")
            cat > "$query_file" << EOF
# 🐛 Debugging & Problem Resolution Query for o3

## Problem Description
$problem_description

## Investigation Context
$additional_context

## Analysis Request
Analyze and provide comprehensive solutions for this technical issue:

### 1. Root Cause Analysis
- Systematic problem breakdown and analysis
- Potential cause identification with reasoning
- Environmental and contextual factor analysis

### 2. Current Investigation Review
- Evaluation of attempted solutions and approaches
- Analysis of error patterns and symptoms
- System state and configuration review

### 3. Solution Strategies
- Multiple solution approaches with detailed pros/cons
- Risk assessment for each approach
- Implementation complexity and resource requirements

### 4. Step-by-Step Resolution
- Detailed implementation guidance for chosen solution
- Testing and validation procedures
- Rollback and recovery strategies

### 5. Prevention & Monitoring
- Future prevention strategies and best practices
- Monitoring and alerting recommendations
- Documentation and knowledge sharing approaches

Please provide comprehensive diagnostic procedures and solution implementations.
EOF
            ;;
        *)
            cat > "$query_file" << EOF
# 🔍 General Research Query for o3

## Problem Statement
$problem_description

## Context
$additional_context

## Research Areas
1. **Current Best Practices**: Latest industry standards and approaches
2. **Implementation Options**: Available solutions and their trade-offs
3. **Technical Considerations**: Performance, security, and scalability factors
4. **Integration Aspects**: Compatibility and ecosystem considerations
5. **Future Planning**: Long-term strategy and evolution paths

Please provide comprehensive analysis and actionable recommendations.
EOF
            ;;
    esac
    
    log_success "✅ o3クエリ生成完了: $query_file"
    echo "$query_file"
}

# 📋 o3連携実行ガイド表示
show_o3_collaboration_guide() {
    cat << 'EOF'
# 🧠 o3連携実行ガイド

## 📞 o3との対話実行手順

### 1. Claude Code内でo3リサーチ実行
```
mcp__o3-search__o3-search tool を使用
生成されたクエリファイルの内容をinputパラメータに設定
```

### 2. o3レスポンス分析
- 提案された解決策の評価
- プロジェクト要件との適合性確認
- 実装可能性・リスク評価

### 3. 追加質問・深掘り
- 不明点の明確化
- 代替案の詳細確認
- 実装時の注意点確認

### 4. 段階的実装
- o3推奨手法の段階的適用
- 各段階での検証・テスト
- 問題発生時の再相談

### 5. 結果記録・共有
- 解決プロセスの文書化
- work-records.mdへの詳細記録
- 知識ベース更新

## 🎯 効果的な対話のコツ

1. **具体的な質問**: 曖昧ではなく具体的な課題設定
2. **コンテキスト提供**: 十分な背景情報の提供
3. **段階的深掘り**: 大問題を小問題に分割
4. **実装検証**: 理論と実際のギャップ確認

EOF
}

# ================================================================================
# 🎯 メイン実行部分
# ================================================================================

main() {
    local command="${1:-help}"
    local problem_description="${2:-}"
    local problem_type="${3:-general}"
    local additional_context="${4:-}"
    
    case "$command" in
        "assess")
            if [ -z "$problem_description" ]; then
                log_error "問題説明が必要です"
                echo "使用法: $0 assess \"問題の説明\""
                exit 1
            fi
            
            complexity=$(assess_problem_complexity "$problem_description")
            score=$?
            
            echo ""
            echo "🔍 判定結果: $complexity (スコア: $score)"
            
            if [ "$complexity" = "HIGH" ] || [ "$complexity" = "MEDIUM" ]; then
                echo "📞 o3連携を推奨します"
                echo "次のステップ: $0 query \"$problem_type\" \"$problem_description\""
            fi
            ;;
            
        "query")
            if [ -z "$problem_description" ]; then
                log_error "問題説明が必要です"
                echo "使用法: $0 query [technical|architecture|debugging|general] \"問題の説明\" \"追加コンテキスト\""
                exit 1
            fi
            
            query_file=$(generate_o3_query "$problem_type" "$problem_description" "$additional_context")
            
            echo ""
            echo "📋 生成されたクエリファイル: $query_file"
            echo ""
            echo "🔍 クエリ内容プレビュー:"
            echo "----------------------------------------"
            head -20 "$query_file"
            echo "----------------------------------------"
            echo ""
            echo "📞 次のステップ: Claude Code内でmcp__o3-search__o3-searchツールを使用"
            ;;
            
        "guide")
            show_o3_collaboration_guide
            ;;
            
        "help"|*)
            cat << 'EOF'
# 🧠 o3連携ヘルパーシステム

## 使用法

### 🔍 問題難易度判定
```bash
./o3-integration-helper.sh assess "問題の説明"
```

### 🎯 o3リサーチクエリ生成
```bash
./o3-integration-helper.sh query [technical|architecture|debugging|general] "問題の説明" "追加コンテキスト"
```

### 📋 連携ガイド表示
```bash
./o3-integration-helper.sh guide
```

## 例

### 技術調査
```bash
./o3-integration-helper.sh assess "最新のReact 19とNext.js 15の統合でSSRパフォーマンス最適化"
./o3-integration-helper.sh query technical "React 19 + Next.js 15 SSR optimization" "現在のアプリは10万ユーザー規模"
```

### アーキテクチャ設計
```bash
./o3-integration-helper.sh query architecture "マイクロサービス設計でリアルタイム処理" "WebSocket + Kafka + Redis"
```

### デバッグ支援
```bash
./o3-integration-helper.sh query debugging "Kubernetes上でメモリリーク発生" "Pod再起動が頻発、ログに明確なエラーなし"
```

EOF
            ;;
    esac
}

# 引数をmainに渡して実行
main "$@"