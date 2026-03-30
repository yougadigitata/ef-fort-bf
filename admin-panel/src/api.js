// API Client — EF-FORT.BF CMS Admin v6.0
const BASE_URL = typeof window !== 'undefined'
    ? (window.location.hostname === 'localhost' ? 'http://localhost:8787' : 'https://ef-fort-bf.pages.dev')
    : 'https://ef-fort-bf.pages.dev';
const CMS_BASE = `${BASE_URL}/api/admin-cms`;
export function getToken() {
    return localStorage.getItem('admin_token');
}
export function setToken(token) {
    localStorage.setItem('admin_token', token);
}
export function clearToken() {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
}
function authHeaders() {
    const token = getToken();
    return {
        'Content-Type': 'application/json',
        ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
    };
}
async function apiCall(url, options = {}) {
    const res = await fetch(url, {
        ...options,
        headers: { ...authHeaders(), ...(options.headers ?? {}) },
    });
    const data = await res.json().catch(() => ({ error: 'Réponse invalide' }));
    if (!res.ok)
        throw new Error(data.error ?? `Erreur ${res.status}`);
    return data;
}
// ── Auth ─────────────────────────────────────────────────────
export async function login(telephone, password) {
    const data = await apiCall(`${BASE_URL}/api/auth/login`, {
        method: 'POST',
        body: JSON.stringify({ telephone, password }),
    });
    if (!data.token)
        throw new Error('Token manquant');
    if (!data.user?.is_admin)
        throw new Error('Accès non autorisé (admin requis)');
    return data;
}
// ── Dashboard ─────────────────────────────────────────────────
export async function getDashboard() {
    return apiCall(`${CMS_BASE}/analytics/dashboard`);
}
// ── Questions ─────────────────────────────────────────────────
export async function getQuestions(params) {
    const qs = new URLSearchParams();
    if (params.matiere)
        qs.set('matiere', params.matiere);
    if (params.serie_id)
        qs.set('serie_id', params.serie_id);
    if (params.difficulte && params.difficulte !== 'TOUS')
        qs.set('difficulte', params.difficulte);
    if (params.search)
        qs.set('search', params.search);
    if (params.page)
        qs.set('page', params.page.toString());
    if (params.limit)
        qs.set('limit', params.limit.toString());
    return apiCall(`${CMS_BASE}/questions?${qs}`);
}
export async function getQuestion(id) {
    return apiCall(`${CMS_BASE}/questions/${id}`);
}
export async function createQuestion(data) {
    return apiCall(`${CMS_BASE}/questions`, { method: 'POST', body: JSON.stringify(data) });
}
export async function updateQuestion(id, data) {
    return apiCall(`${CMS_BASE}/questions/${id}`, { method: 'PUT', body: JSON.stringify(data) });
}
export async function deleteQuestion(id, soft = false) {
    return apiCall(`${CMS_BASE}/questions/${id}?soft=${soft}`, { method: 'DELETE' });
}
export async function duplicateQuestion(id) {
    return apiCall(`${CMS_BASE}/questions/${id}/duplicate`, { method: 'POST' });
}
// ── Bulk Import ───────────────────────────────────────────────
export async function validateBulk(data, matiereId) {
    return apiCall(`${CMS_BASE}/questions/validate-bulk`, {
        method: 'POST',
        body: JSON.stringify({ questions: data, matiere_id: matiereId }),
    });
}
export async function bulkImport(data, matiereId) {
    return apiCall(`${CMS_BASE}/questions/bulk-import`, {
        method: 'POST',
        body: JSON.stringify({ questions: data, matiere_id: matiereId }),
    });
}
export async function getImportHistory() {
    return apiCall(`${CMS_BASE}/questions/import-history`);
}
export async function cancelImport(importId) {
    return apiCall(`${CMS_BASE}/questions/import/${importId}`, { method: 'DELETE' });
}
// ── Séries ────────────────────────────────────────────────────
export async function getSeries(params) {
    const qs = new URLSearchParams();
    if (params.matiere_id)
        qs.set('matiere_id', params.matiere_id);
    if (params.matiere)
        qs.set('matiere', params.matiere);
    return apiCall(`${CMS_BASE}/series?${qs}`);
}
export async function createSerie(data) {
    return apiCall(`${CMS_BASE}/series`, { method: 'POST', body: JSON.stringify(data) });
}
export async function autoGenerateSerie(matiereId, count = 20) {
    return apiCall(`${CMS_BASE}/series/auto-generate`, {
        method: 'POST', body: JSON.stringify({ matiere_id: matiereId, count }),
    });
}
export async function updateSerie(id, data) {
    return apiCall(`${CMS_BASE}/series/${id}`, { method: 'PUT', body: JSON.stringify(data) });
}
export async function deleteSerie(id, orphan = 'keep') {
    return apiCall(`${CMS_BASE}/series/${id}?orphan=${orphan}`, { method: 'DELETE' });
}
// ── Simulations ───────────────────────────────────────────────
export async function getSimulations() {
    return apiCall(`${CMS_BASE}/simulations`);
}
export async function getSimulation(id) {
    return apiCall(`${CMS_BASE}/simulations/${id}`);
}
export async function createSimulation(data) {
    return apiCall(`${CMS_BASE}/simulations`, { method: 'POST', body: JSON.stringify(data) });
}
export async function updateSimulation(id, data) {
    return apiCall(`${CMS_BASE}/simulations/${id}`, { method: 'PUT', body: JSON.stringify(data) });
}
export async function deleteSimulation(id) {
    return apiCall(`${CMS_BASE}/simulations/${id}`, { method: 'DELETE' });
}
// ── Analytics ─────────────────────────────────────────────────
export async function getFlags(status = 'new', page = 1) {
    return apiCall(`${CMS_BASE}/flags?status=${status}&page=${page}`);
}
export async function resolveFlag(id, adminNote, status = 'resolved') {
    return apiCall(`${CMS_BASE}/flags/${id}`, {
        method: 'PUT',
        body: JSON.stringify({ status, admin_note: adminNote }),
    });
}
export async function getAuditLog(page = 1) {
    return apiCall(`${CMS_BASE}/audit-log?page=${page}`);
}
// ── Matières ──────────────────────────────────────────────────
export async function getMatieres() {
    return apiCall(`${CMS_BASE}/matieres`);
}
// ── Migration ─────────────────────────────────────────────────
export async function runMigration() {
    return apiCall(`${CMS_BASE}/migrate-cms`, {
        method: 'POST',
        body: JSON.stringify({ secret: 'EfFortCMS2026!Migration' }),
    });
}
// ── Admin Stats ──────────────────────────────────────────────
export async function getAdminStats() {
    return apiCall(`${BASE_URL}/api/admin/stats`);
}
