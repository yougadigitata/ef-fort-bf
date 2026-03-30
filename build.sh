#!/bin/bash
# build.sh — Script de build complet EF-FORT.BF v6.0
# Compile le backend Hono + build le panel admin React

echo "🚀 Build EF-FORT.BF v6.0 — CMS Admin Revolution"
echo "=================================================="

# 1. Build backend TypeScript
echo "📦 Compilation backend TypeScript..."
npm run build

# 2. Build admin panel React
echo "⚛️ Build Admin Panel React..."
cd admin-panel && npm run build && cd ..

echo "✅ Build complet terminé !"
echo "  - Backend : src/*.js"
echo "  - Admin Panel : admin-dist/"
