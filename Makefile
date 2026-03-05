# MotoTrace Makefile

.PHONY: generate clean feature module install edit

# Xcode 프로젝트 생성
generate:
	tuist generate

# 캐시/파생 파일 정리 후 재생성
clean:
	tuist clean
	tuist generate

# Feature 모듈 생성
# 사용법: make feature name=HistoryDetail
feature:
	@if [ -z "$(name)" ]; then \
		echo "❌ 사용법: make feature name=모듈이름"; \
		exit 1; \
	fi
	tuist scaffold feature --name $(name)
	@echo ""
	@echo "✅ Feature$(name) 모듈 생성 완료"
	@echo "📝 ModuleName.swift에 case 등록 필요!"

# 프로젝트 편집 (Tuist manifest 수정용)
edit:
	tuist edit

# 도움말
help:
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo "  MotoTrace Makefile"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "  make generate          Xcode 프로젝트 생성"
	@echo "  make clean             정리 후 재생성"
	@echo "  make feature name=XX   Feature 모듈 생성"
	@echo "  make edit              Tuist manifest 편집"
	@echo "  make help              도움말"
	@echo ""
