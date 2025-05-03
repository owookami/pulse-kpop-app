/**
 * Pulse 크롤러 관리자 대시보드 스크립트
 */

// API 기본 URL
const API_BASE_URL = '/api';

// 페이지 전환 함수
function showPage(pageId) {
    // 모든 페이지 숨기기
    document.querySelectorAll('.page').forEach(page => {
        page.style.display = 'none';
    });

    // 선택한 페이지 표시
    document.getElementById(pageId).style.display = 'block';

    // 사이드바 메뉴 활성화 처리
    document.querySelectorAll('.nav-link').forEach(link => {
        link.classList.remove('active');
    });

    document.querySelector(`.nav-link[data-page="${pageId}"]`).classList.add('active');
}

// 날짜 포맷팅 함수
function formatDate(dateString) {
    if (!dateString) return '-';

    const date = new Date(dateString);
    return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')} ${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}:${String(date.getSeconds()).padStart(2, '0')}`;
}

// 작업 상태에 따른 배지 반환
function getStatusBadge(status) {
    switch (status) {
        case 'pending':
            return '<span class="badge bg-secondary">대기 중</span>';
        case 'running':
            return '<span class="badge bg-primary">실행 중</span>';
        case 'completed':
            return '<span class="badge bg-success">완료</span>';
        case 'failed':
            return '<span class="badge bg-danger">실패</span>';
        default:
            return '<span class="badge bg-secondary">' + status + '</span>';
    }
}

// 검색 조건 텍스트 생성
function getSearchConditionText(params) {
    const conditions = [];

    if (params.artist) {
        conditions.push(`아티스트: ${params.artist}`);
    }

    if (params.group) {
        conditions.push(`그룹: ${params.group}`);
    }

    if (params.event) {
        conditions.push(`이벤트: ${params.event}`);
    }

    if (params.start_date || params.end_date) {
        let dateRange = '날짜: ';
        if (params.start_date) {
            dateRange += params.start_date;
        }
        dateRange += ' ~ ';
        if (params.end_date) {
            dateRange += params.end_date;
        }
        conditions.push(dateRange);
    }

    if (conditions.length === 0) {
        return '전체 검색';
    }

    return conditions.join(', ');
}

// 작업 목록 렌더링
function renderJobs(jobs, targetElementId, limit = null) {
    const tbody = document.getElementById(targetElementId);

    if (!jobs || jobs.length === 0) {
        tbody.innerHTML = '<tr><td colspan="6" class="text-center">작업이 없습니다.</td></tr>';
        return;
    }

    // 작업 정렬 (최신순)
    jobs.sort((a, b) => new Date(b.start_time) - new Date(a.start_time));

    // 제한이 있는 경우 적용
    const displayJobs = limit ? jobs.slice(0, limit) : jobs;

    let html = '';

    displayJobs.forEach(job => {
        const jobId = job.id;
        const statusBadge = getStatusBadge(job.status);

        // 작업 ID에서 params를 추출
        let params = {};
        try {
            // /jobs/:id API 호출로 얻은 작업 정보에서 params 추출
            if (job.params) {
                params = job.params;
            }
        } catch (error) {
            console.error('Error parsing job params:', error);
        }

        const searchCondition = getSearchConditionText(params);

        html += `
            <tr>
                <td>${jobId}</td>
                <td>${statusBadge}</td>
                <td>${searchCondition}</td>
                <td>${formatDate(job.start_time)}</td>
                <td>${formatDate(job.end_time || '')}</td>
                <td>
                    <button class="btn btn-sm btn-outline-primary me-1" onclick="showJobDetail('${jobId}')">
                        <i class="bi bi-info-circle"></i> 상세
                    </button>`;

        if (job.status !== 'running' && job.status !== 'pending') {
            html += `
                <button class="btn btn-sm btn-outline-danger" onclick="deleteJob('${jobId}')">
                    <i class="bi bi-trash"></i> 삭제
                </button>`;
        }

        html += `
                </td>
            </tr>
        `;
    });

    tbody.innerHTML = html;
}

// 아티스트 목록 로드 및 렌더링
async function loadArtists() {
    try {
        const response = await fetch(`${API_BASE_URL}/artists`);
        const artists = await response.json();

        // 아티스트 목록 테이블 렌더링
        const tbody = document.getElementById('artists-tbody');
        let html = '';

        artists.forEach(artist => {
            html += `
                <tr>
                    <td>${artist.id}</td>
                    <td>${artist.name}</td>
                    <td>${artist.groupName || '-'}</td>
                </tr>
            `;
        });

        tbody.innerHTML = html;

        // 아티스트 드롭다운 옵션 추가
        const artistSelect = document.getElementById('artist');
        let optionsHtml = '<option value="">선택 (옵션)</option>';

        artists.forEach(artist => {
            optionsHtml += `<option value="${artist.name}">${artist.name}</option>`;
        });

        artistSelect.innerHTML = optionsHtml;

    } catch (error) {
        console.error('아티스트 로드 오류:', error);
    }
}

// 그룹 목록 로드 및 렌더링
async function loadGroups() {
    try {
        const response = await fetch(`${API_BASE_URL}/groups`);
        const groups = await response.json();

        // 그룹 목록 테이블 렌더링
        const tbody = document.getElementById('groups-tbody');
        let html = '';

        groups.forEach(group => {
            html += `
                <tr>
                    <td>${group.id}</td>
                    <td>${group.name}</td>
                </tr>
            `;
        });

        tbody.innerHTML = html;

        // 그룹 드롭다운 옵션 추가
        const groupSelect = document.getElementById('group');
        let optionsHtml = '<option value="">선택 (옵션)</option>';

        groups.forEach(group => {
            optionsHtml += `<option value="${group.name}">${group.name}</option>`;
        });

        groupSelect.innerHTML = optionsHtml;

    } catch (error) {
        console.error('그룹 로드 오류:', error);
    }
}

// 작업 목록 로드
async function loadJobs() {
    try {
        const response = await fetch(`${API_BASE_URL}/jobs`);
        const jobs = await response.json();

        // 대시보드 최근 작업 목록
        renderJobs(jobs, 'recent-jobs-tbody', 5);

        // 작업 목록 페이지
        renderJobs(jobs, 'jobs-tbody');

    } catch (error) {
        console.error('작업 로드 오류:', error);
    }
}

// 통계 로드
async function loadStats() {
    try {
        const response = await fetch(`${API_BASE_URL}/stats`);
        const stats = await response.json();

        document.getElementById('total-jobs').textContent = stats.total_jobs;
        document.getElementById('completed-jobs').textContent = stats.completed_jobs;
        document.getElementById('running-jobs').textContent = stats.running_jobs;
        document.getElementById('failed-jobs').textContent = stats.failed_jobs;

    } catch (error) {
        console.error('통계 로드 오류:', error);
    }
}

// 작업 상세 정보 표시
async function showJobDetail(jobId) {
    try {
        const response = await fetch(`${API_BASE_URL}/jobs/${jobId}`);
        const job = await response.json();

        const modalBody = document.getElementById('job-detail-content');
        let html = '';

        // 작업 기본 정보
        html += `
            <div class="mb-4">
                <h5 class="border-bottom pb-2 mb-3">기본 정보</h5>
                <div class="row">
                    <div class="col-md-6">
                        <p><strong>작업 ID:</strong> ${job.id}</p>
                        <p><strong>상태:</strong> ${getStatusBadge(job.status)}</p>
                        <p><strong>시작 시간:</strong> ${formatDate(job.start_time)}</p>
                        <p><strong>완료 시간:</strong> ${formatDate(job.end_time || '')}</p>
                    </div>
                    <div class="col-md-6">`;

        // 작업 매개변수 정보
        if (job.params) {
            const params = job.params;
            html += `
                        <p><strong>아티스트:</strong> ${params.artist || '-'}</p>
                        <p><strong>그룹:</strong> ${params.group || '-'}</p>
                        <p><strong>이벤트:</strong> ${params.event || '-'}</p>
                        <p><strong>검색 결과 수:</strong> ${params.limit}</p>
                        <p><strong>기간:</strong> ${params.start_date || ''} ~ ${params.end_date || ''}</p>
            `;
        }

        html += `
                    </div>
                </div>
            </div>
        `;

        // 작업 결과 정보
        if (job.status === 'completed' && job.result) {
            html += `
                <div class="mb-4">
                    <h5 class="border-bottom pb-2 mb-3">결과</h5>
                    <p><strong>메시지:</strong> ${job.result.message || ''}</p>
                    <p><strong>출력 디렉토리:</strong> ${job.result.output_dir || ''}</p>
                </div>
            `;

            if (job.result.files && job.result.files.length > 0) {
                html += `
                    <div class="mb-4">
                        <h5 class="border-bottom pb-2 mb-3">파일</h5>
                        <ul class="list-group">
                `;

                job.result.files.forEach(file => {
                    html += `<li class="list-group-item">${file}</li>`;
                });

                html += `
                        </ul>
                    </div>
                `;
            }
        }

        // 실패 정보
        if (job.status === 'failed' && job.result && job.result.error) {
            html += `
                <div class="mb-4">
                    <h5 class="border-bottom pb-2 mb-3 text-danger">오류</h5>
                    <div class="alert alert-danger">
                        <pre class="mb-0">${job.result.error}</pre>
                    </div>
                </div>
            `;
        }

        modalBody.innerHTML = html;

        // 모달 표시
        const modal = new bootstrap.Modal(document.getElementById('job-detail-modal'));
        modal.show();

    } catch (error) {
        console.error('작업 상세 정보 로드 오류:', error);
        alert('작업 상세 정보를 불러오는 데 실패했습니다.');
    }
}

// 작업 삭제
async function deleteJob(jobId) {
    if (!confirm('이 작업을 삭제하시겠습니까?')) {
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/jobs/${jobId}`, {
            method: 'DELETE'
        });

        if (response.ok) {
            alert('작업이 삭제되었습니다.');
            loadJobs();
            loadStats();
        } else {
            const error = await response.json();
            alert(`작업 삭제 실패: ${error.detail}`);
        }
    } catch (error) {
        console.error('작업 삭제 오류:', error);
        alert('작업을 삭제하는 데 실패했습니다.');
    }
}

// Cron 표현식의 인간 친화적 설명 반환
function getCronDescription(expression) {
    const parts = expression.split(' ');
    if (parts.length !== 5) return expression;

    let description = '';

    // 간단한 패턴에 대한 설명
    if (expression === '0 0 * * *') {
        description = '매일 00:00';
    } else if (expression === '0 0 * * 0') {
        description = '매주 일요일 00:00';
    } else if (expression === '0 0 1 * *') {
        description = '매월 1일 00:00';
    } else if (expression === '0 0 1 1 *') {
        description = '매년 1월 1일 00:00';
    } else if (parts[0] === '0' && parts[1] === '0') {
        description = '매일 00:00';
    } else if (parts[0] === '0' && parts[2] === '*' && parts[3] === '*') {
        description = `매일 ${parts[1]}:00`;
    } else {
        description = expression;
    }

    return `${description} (${expression})`;
}

// 예약 작업 목록 로드
async function loadScheduledJobs() {
    try {
        const response = await fetch(`${API_BASE_URL}/scheduled-jobs`);
        const jobs = await response.json();

        const tbody = document.getElementById('scheduled-jobs-tbody');

        if (!jobs || jobs.length === 0) {
            tbody.innerHTML = '<tr><td colspan="7" class="text-center">예약된 작업이 없습니다.</td></tr>';
            return;
        }

        // 작업 정렬 (이름순)
        jobs.sort((a, b) => a.name.localeCompare(b.name));

        let html = '';

        jobs.forEach(job => {
            const jobId = job.id;
            const statusBadge = job.is_active
                ? '<span class="badge bg-success">활성</span>'
                : '<span class="badge bg-secondary">비활성</span>';

            const searchCondition = getSearchConditionText(job.params || {});
            const cronDescription = getCronDescription(job.cron_expression);

            html += `
                <tr>
                    <td>${job.name}</td>
                    <td>${cronDescription}</td>
                    <td>${searchCondition}</td>
                    <td>${statusBadge}</td>
                    <td>${formatDate(job.last_run || '')}</td>
                    <td>${formatDate(job.next_run || '')}</td>
                    <td>
                        <button class="btn btn-sm btn-outline-primary me-1" onclick="editScheduledJob('${jobId}')">
                            <i class="bi bi-pencil"></i> 편집
                        </button>
                        <button class="btn btn-sm btn-outline-${job.is_active ? 'warning' : 'success'}" onclick="toggleScheduledJob('${jobId}', ${!job.is_active})">
                            <i class="bi bi-${job.is_active ? 'pause' : 'play'}"></i> ${job.is_active ? '중지' : '시작'}
                        </button>
                        <button class="btn btn-sm btn-outline-danger" onclick="deleteScheduledJob('${jobId}')">
                            <i class="bi bi-trash"></i> 삭제
                        </button>
                    </td>
                </tr>
            `;
        });

        tbody.innerHTML = html;

    } catch (error) {
        console.error('예약 작업 로드 오류:', error);
    }
}

// 크론 표현식 검증 함수
function validateCronExpression(cronExpression) {
    // 빈 문자열 체크
    if (!cronExpression || cronExpression.trim() === '') {
        return { valid: false, message: '크론 표현식을 입력해주세요.' };
    }

    // 기본 형식 검증 (공백으로 구분된 5개 또는 6개 필드)
    const parts = cronExpression.trim().split(/\s+/);
    if (parts.length < 5 || parts.length > 6) {
        return {
            valid: false,
            message: '크론 표현식은 5개 또는 6개의 필드로 구성되어야 합니다. (분 시 일 월 요일 [년])'
        };
    }

    // 각 필드의 기본 패턴 검증
    const patterns = [
        /^(\*|([0-9]|[1-5][0-9])(-([0-9]|[1-5][0-9]))?(\/\d+)?)(,(\*|([0-9]|[1-5][0-9])(-([0-9]|[1-5][0-9]))?(\/\d+)?))*$/, // 분 (0-59)
        /^(\*|([0-9]|1[0-9]|2[0-3])(-([0-9]|1[0-9]|2[0-3]))?(\/\d+)?)(,(\*|([0-9]|1[0-9]|2[0-3])(-([0-9]|1[0-9]|2[0-3]))?(\/\d+)?))*$/, // 시 (0-23)
        /^(\*|([1-9]|[12][0-9]|3[01])(-([1-9]|[12][0-9]|3[01]))?(\/\d+)?)(,(\*|([1-9]|[12][0-9]|3[01])(-([1-9]|[12][0-9]|3[01]))?(\/\d+)?))*$/, // 일 (1-31)
        /^(\*|([1-9]|1[0-2])(-([1-9]|1[0-2]))?(\/\d+)?)(,(\*|([1-9]|1[0-2])(-([1-9]|1[0-2]))?(\/\d+)?))*$/, // 월 (1-12)
        /^(\*|([0-6])(-([0-6]))?(\/\d+)?)(,(\*|([0-6])(-([0-6]))?(\/\d+)?))*$/ // 요일 (0-6)
    ];

    for (let i = 0; i < Math.min(parts.length, patterns.length); i++) {
        if (!patterns[i].test(parts[i])) {
            const fields = ['분', '시', '일', '월', '요일', '년'];
            return {
                valid: false,
                message: `${fields[i]} 필드(${parts[i]})가 올바르지 않습니다. 올바른 형식을 사용해주세요.`
            };
        }
    }

    return { valid: true };
}

// 예약 작업 추가/편집 모달 열기
function openScheduledJobModal(isEdit = false, jobId = null) {
    const modal = new bootstrap.Modal(document.getElementById('scheduled-job-modal'));
    const modalTitle = document.getElementById('scheduled-job-modal-label');
    const form = document.getElementById('scheduled-job-form');

    // 모달 제목 설정
    modalTitle.textContent = isEdit ? '예약 작업 편집' : '예약 작업 추가';

    // 폼 초기화
    form.reset();
    document.getElementById('scheduled-job-id').value = jobId || '';

    if (isEdit && jobId) {
        // 기존 작업 데이터 로드
        loadScheduledJobData(jobId);
    }

    // 드롭다운 옵션 복사
    copyDropdownOptions('artist', 'scheduled-job-artist');
    copyDropdownOptions('group', 'scheduled-job-group');

    modal.show();
}

// 드롭다운 옵션 복사
function copyDropdownOptions(sourceId, targetId) {
    const sourceSelect = document.getElementById(sourceId);
    const targetSelect = document.getElementById(targetId);

    if (sourceSelect && targetSelect) {
        targetSelect.innerHTML = sourceSelect.innerHTML;
    }
}

// 예약 작업 데이터 로드
async function loadScheduledJobData(jobId) {
    try {
        const response = await fetch(`${API_BASE_URL}/scheduled-jobs/${jobId}`);
        const job = await response.json();

        // 폼에 데이터 채우기
        document.getElementById('scheduled-job-id').value = job.id;
        document.getElementById('scheduled-job-name').value = job.name;
        document.getElementById('scheduled-job-cron').value = job.cron_expression;
        document.getElementById('scheduled-job-artist').value = job.params?.artist || '';
        document.getElementById('scheduled-job-group').value = job.params?.group || '';
        document.getElementById('scheduled-job-event').value = job.params?.event || '';
        document.getElementById('scheduled-job-limit').value = job.params?.limit || 50;
        document.getElementById('scheduled-job-active').checked = job.is_active;
        document.getElementById('scheduled-job-save-to-db').checked = job.params?.save_to_db !== false;

    } catch (error) {
        console.error('예약 작업 데이터 로드 오류:', error);
        alert('예약 작업 정보를 불러오는 데 실패했습니다.');
    }
}

// 예약 작업 저장
async function saveScheduledJob() {
    const form = document.getElementById('scheduled-job-form');
    const formData = new FormData(form);
    const jobId = formData.get('id');
    const cronExpression = formData.get('cron_expression');

    // 크론 표현식 검증
    const cronValidation = validateCronExpression(cronExpression);
    if (!cronValidation.valid) {
        alert(`크론 표현식 오류: ${cronValidation.message}`);
        return;
    }

    // 폼 데이터를 객체로 변환
    const jobData = {
        id: jobId && jobId.trim().length > 0 ? jobId : undefined,  // id가 빈 문자열이면 undefined로 설정하여 서버에서 자동 생성
        name: formData.get('name') || '',  // 빈 값이 아닌 빈 문자열로 설정
        cron_expression: cronExpression || '0 0 * * *',  // 기본값 설정
        is_active: formData.get('is_active') === 'on',
        params: {
            artist: formData.get('artist') || '',  // null이 아닌 빈 문자열로 설정
            group: formData.get('group') || '',
            event: formData.get('event') || '',
            limit: parseInt(formData.get('limit') || '50', 10) || 50,  // 숫자 변환 실패 시 기본값 50
            save_to_db: formData.get('save_to_db') === 'on'
        }
    };

    // 디버깅을 위해 콘솔에 데이터 출력
    console.log('전송할 예약 작업 데이터:', jobData);

    try {
        // ID 확인을 명확하게 처리
        const isNewJob = !jobId || jobId.trim().length === 0;
        const url = isNewJob
            ? `${API_BASE_URL}/scheduled-jobs`
            : `${API_BASE_URL}/scheduled-jobs/${jobId}`;

        const method = isNewJob ? 'POST' : 'PUT';

        const response = await fetch(url, {
            method: method,
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(jobData)
        });

        if (response.ok) {
            const result = await response.json();
            console.log('서버 응답:', result);

            // 모달 닫기
            const modal = bootstrap.Modal.getInstance(document.getElementById('scheduled-job-modal'));
            modal.hide();

            // 작업 목록 새로고침
            loadScheduledJobs();

            alert(isNewJob ? '예약 작업이 추가되었습니다.' : '예약 작업이 업데이트되었습니다.');
        } else {
            const errorText = await response.text();
            let errorMessage = '예약 작업을 저장하는 데 실패했습니다.';

            try {
                const error = JSON.parse(errorText);
                errorMessage = `오류: ${error.detail || errorMessage}`;
            } catch (e) {
                // JSON 파싱에 실패한 경우 원본 텍스트 사용
                errorMessage = `오류: ${errorText || errorMessage}`;
            }

            console.error('API 오류 응답:', errorText);
            alert(errorMessage);
        }
    } catch (error) {
        console.error('예약 작업 저장 오류:', error);
        alert(`예약 작업을 저장하는 데 실패했습니다: ${error.message}`);
    }
}

// 예약 작업 편집
function editScheduledJob(jobId) {
    openScheduledJobModal(true, jobId);
}

// 예약 작업 활성화/비활성화
async function toggleScheduledJob(jobId, active) {
    try {
        const response = await fetch(`${API_BASE_URL}/scheduled-jobs/${jobId}/status`, {
            method: 'PATCH',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ is_active: active })
        });

        if (response.ok) {
            loadScheduledJobs();
            alert(`예약 작업이 ${active ? '활성화' : '비활성화'}되었습니다.`);
        } else {
            const error = await response.json();
            alert(`오류: ${error.detail || '예약 작업 상태를 변경하는 데 실패했습니다.'}`);
        }
    } catch (error) {
        console.error('예약 작업 상태 변경 오류:', error);
        alert('예약 작업 상태를 변경하는 데 실패했습니다.');
    }
}

// 예약 작업 삭제
async function deleteScheduledJob(jobId) {
    if (!confirm('이 예약 작업을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.')) {
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/scheduled-jobs/${jobId}`, {
            method: 'DELETE'
        });

        if (response.ok) {
            loadScheduledJobs();
            alert('예약 작업이 삭제되었습니다.');
        } else {
            const error = await response.json();
            alert(`오류: ${error.detail || '예약 작업을 삭제하는 데 실패했습니다.'}`);
        }
    } catch (error) {
        console.error('예약 작업 삭제 오류:', error);
        alert('예약 작업을 삭제하는 데 실패했습니다.');
    }
}

// 페이지 로드 이벤트
document.addEventListener('DOMContentLoaded', async () => {
    // 페이지 네비게이션 이벤트 리스너
    document.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', event => {
            event.preventDefault();
            const pageId = link.getAttribute('data-page');
            showPage(pageId);
        });
    });

    // 새 크롤링 작업 버튼 이벤트
    document.getElementById('new-job-btn').addEventListener('click', () => {
        showPage('new-job');
    });

    // 취소 버튼 이벤트
    document.getElementById('cancel-job').addEventListener('click', () => {
        showPage('dashboard');
    });

    // 새로고침 버튼 이벤트
    document.getElementById('refresh-stats').addEventListener('click', () => {
        loadStats();
        loadJobs();
    });

    document.getElementById('refresh-jobs').addEventListener('click', () => {
        loadJobs();
    });

    // 크롤링 폼 제출 이벤트
    document.getElementById('crawler-form').addEventListener('submit', async event => {
        event.preventDefault();

        const formData = new FormData(event.target);
        const formObject = Object.fromEntries(formData.entries());

        // 체크박스 처리
        formObject.save_to_db = formObject.save_to_db === 'on';
        formObject.download_thumbnails = formObject.download_thumbnails === 'on';
        formObject.skip_existing = formObject.skip_existing === 'on';

        // 숫자 필드 처리
        formObject.limit = parseInt(formObject.limit);

        try {
            const response = await fetch(`${API_BASE_URL}/jobs`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(formObject)
            });

            const result = await response.json();

            if (response.ok) {
                alert('크롤링 작업이 시작되었습니다.');
                showPage('job-list');
                loadJobs();
                loadStats();
            } else {
                alert(`크롤링 작업 시작 실패: ${result.detail}`);
            }
        } catch (error) {
            console.error('크롤링 작업 시작 오류:', error);
            alert('크롤링 작업을 시작하는 데 실패했습니다.');
        }
    });

    // 예약 작업 새로고침 버튼 이벤트
    document.getElementById('refresh-scheduled-jobs').addEventListener('click', () => {
        loadScheduledJobs();
    });

    // 새 예약 작업 버튼 이벤트
    document.getElementById('add-scheduled-job-btn').addEventListener('click', () => {
        openScheduledJobModal(false);
    });

    // 예약 작업 저장 버튼 이벤트
    document.getElementById('save-scheduled-job').addEventListener('click', () => {
        saveScheduledJob();
    });

    // 초기 데이터 로드
    await Promise.all([
        loadArtists(),
        loadGroups(),
        loadJobs(),
        loadStats(),
        loadScheduledJobs()
    ]);
});

// 전역 함수 등록
window.showJobDetail = showJobDetail;
window.deleteJob = deleteJob;
window.editScheduledJob = editScheduledJob;
window.toggleScheduledJob = toggleScheduledJob;
window.deleteScheduledJob = deleteScheduledJob; 