#!/bin/bash

# Cloudflare API credentials
CF_API_TOKEN="your-api-token"
CF_ZONE_ID="your-zone-id"
CF_RECORD_ID="your-record-id" #DDNS record
CF_RECORD_NAME="your-domain.com"

# 获取当前公网IP
CURRENT_IP=$(curl -s http://whatismyip.akamai.com/)

# 获取当前Cloudflare记录的IP
RECORD_INFO=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/${CF_RECORD_ID}" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json")

CLOUDFLARE_IP=$(echo $RECORD_INFO | jq -r '.result.content')
SUCCESS=$(echo $RECORD_INFO | jq -r '.success')

# 检查API请求是否成功
if [ "$SUCCESS" != "true" ]; then
  echo "无法获取DNS记录信息。"
  exit 1
fi

# 比较IP地址
if [ "$CURRENT_IP" = "$CLOUDFLARE_IP" ]; then
  echo "Cloudflare DDNS正常，IP未更新。当前IP为: ${CURRENT_IP}"
  exit 0
fi

# 如果IP地址不同，则更新DNS记录
UPDATE_RESPONSE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${CF_ZONE_ID}/dns_records/${CF_RECORD_ID}" \
  -H "Authorization: Bearer ${CF_API_TOKEN}" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"A\",\"name\":\"${CF_RECORD_NAME}\",\"content\":\"${CURRENT_IP}\",\"1\":120,\"proxied\":false}")

# 检查更新响应
UPDATE_SUCCESS=$(echo $UPDATE_RESPONSE | jq -r '.success')

if [ "$UPDATE_SUCCESS" = "true" ]; then
  # 输出更新前后的IP地址
  echo "地址已从 ${CLOUDFLARE_IP} 更新至 ${CURRENT_IP}"
else
  ERROR=$(echo $UPDATE_RESPONSE | jq -r '.errors[0].message')
  echo "更新失败: $ERROR"
  exit 1
fi
