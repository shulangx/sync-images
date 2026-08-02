#!/bin/bash
# ============================================
# Node-0 ACR 镜像批量拉取工具（Alpine 优先版）
# 用法: ./pull-aliyun.sh [images.txt]
# ============================================

# ============================================
# 配置（请根据实际情况修改）
# ============================================
ALIYUN_REGISTRY="registry.cn-hangzhou.aliyuncs.com"
ALIYUN_NAMESPACE="my-namespace"
IMAGES_FILE="${1:-images.txt}"

# ============================================
# 颜色输出
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ============================================
# 函数：从 ACR 镜像地址提取短名
# ============================================
extract_short_name() {
    local full_image="$1"
    # 先移除注册地址部分（前缀）
    local without_registry="${full_image#*/}"
    # 再移除命名空间部分
    local without_namespace="${without_registry#*/}"
    # 返回剩余部分（仓库名:标签）
    echo "$without_namespace"
}

# ============================================
# 函数：拉取单个镜像
# ============================================
pull_aliyun_image() {
    local full_image="$1"
    local short_name=$(extract_short_name "$full_image")
    
    echo -e "${GREEN}📥 拉取:${NC} $full_image"
    
    if docker pull "$full_image"; then
        echo -e "${GREEN}🏷️  重命名:${NC} $short_name"
        docker tag "$full_image" "$short_name"
        
        echo -e "${GREEN}🧹 清理:${NC} 删除长名称"
        docker rmi "$full_image" >/dev/null 2>&1 || true
        
        echo -e "${GREEN}✅ 完成:${NC} $short_name"
        return 0
    else
        echo -e "${RED}❌ 拉取失败:${NC} $full_image"
        return 1
    fi
}

# ============================================
# 主循环：批量处理
# ============================================
echo -e "${YELLOW}============================================${NC}"
echo -e "${YELLOW}🚀 Node-0 ACR 镜像批量拉取工具${NC}"
echo -e "${YELLOW}（Alpine 优先版）${NC}"
echo -e "${YELLOW}============================================${NC}"
echo ""

if [ ! -f "$IMAGES_FILE" ]; then
    echo -e "${RED}❌ 错误: 找不到镜像清单文件 $IMAGES_FILE${NC}"
    exit 1
fi

SUCCESS=0
FAIL=0

while IFS= read -r line || [ -n "$line" ]; do
    # 跳过注释行和空行
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
    
    # 从 images.txt 读取源镜像名
    source_image="$line"
    
    # 提取仓库名（用于构建 ACR 地址）
    repo_name=$(echo "$source_image" | sed 's|.*/||' | cut -d':' -f1)
    tag="${source_image##*:}"
    [ "$tag" = "$source_image" ] && tag="latest"
    
    # 构建完整的 ACR 镜像地址
    full_image="${ALIYUN_REGISTRY}/${ALIYUN_NAMESPACE}/${repo_name}:${tag}"
    
    echo ""
    echo -e "${YELLOW}--- 处理: $source_image ---${NC}"
    
    if pull_aliyun_image "$full_image"; then
        SUCCESS=$((SUCCESS + 1))
    else
        FAIL=$((FAIL + 1))
    fi
    
done < "$IMAGES_FILE"

# ============================================
# 输出汇总
# ============================================
echo ""
echo -e "${YELLOW}============================================${NC}"
echo -e "${GREEN}✅ 成功: $SUCCESS${NC}"
echo -e "${RED}❌ 失败: $FAIL${NC}"
echo -e "${YELLOW}============================================${NC}"

if [ $FAIL -gt 0 ]; then
    exit 1
fi
