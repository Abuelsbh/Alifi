// Global variables
let currentUser = null;
let veterinariansData = [];
let petStoresData = [];
let unsubscribeVets = null;
let unsubscribeStores = null;
let currentEditingVet = null;
let currentEditingStore = null;

// DOM elements
const loadingScreen = document.getElementById('loading-screen');
const loginContainer = document.getElementById('login-container');
const dashboardContainer = document.getElementById('dashboard-container');
const loginForm = document.getElementById('login-form');
const logoutBtn = document.getElementById('logout-btn');

// Navigation
const navItems = document.querySelectorAll('.nav-item');
const pages = document.querySelectorAll('.page');
const pageTitle = document.getElementById('page-title');
const userName = document.getElementById('user-name');

// Veterinarians elements
const addVetBtn = document.getElementById('add-vet-btn');
const vetModal = document.getElementById('vet-modal');
const vetForm = document.getElementById('vet-form');
const vetSearch = document.getElementById('vet-search');
const filterBtns = document.querySelectorAll('.filter-btn');
const vetsTableBody = document.getElementById('vets-table-body');

// Pet Stores elements
const addStoreBtn = document.getElementById('add-store-btn');
const storeModal = document.getElementById('store-modal');
const storeForm = document.getElementById('store-form');
const storeSearch = document.getElementById('store-search');
const storesGrid = document.getElementById('stores-grid');

// Statistics elements
const totalVetsEl = document.getElementById('total-vets');
const totalUsersEl = document.getElementById('total-users');
const totalStoresEl = document.getElementById('total-stores');
const totalPetsEl = document.getElementById('total-pets');
const totalChatsEl = document.getElementById('total-chats');
const recentActivityEl = document.getElementById('recent-activity');

// Initialize app
document.addEventListener('DOMContentLoaded', async () => {
    console.log('🚀 Initializing Admin Dashboard...');
    
    try {
        // Check authentication state
        FirebaseService.onAuthStateChanged((user) => {
            if (user) {
                console.log('✅ User authenticated:', user.email);
                currentUser = user;
                showDashboard();
                loadDashboardData();
            } else {
                console.log('❌ User not authenticated');
                showLogin();
            }
        });
    } catch (error) {
        console.error('❌ Error initializing app:', error);
        showLogin();
    }
    
    // Initialize event listeners
    initializeEventListeners();
});

// Event listeners
function initializeEventListeners() {
    // Login form
    loginForm.addEventListener('submit', handleLogin);
    
    // Logout button
    logoutBtn.addEventListener('click', handleLogout);
    
    // Navigation
    navItems.forEach(item => {
        item.addEventListener('click', (e) => {
            e.preventDefault();
            const page = item.dataset.page;
            navigateToPage(page);
        });
    });
    
    // Add veterinarian button
    addVetBtn.addEventListener('click', () => openVetModal());
    
    // Add pet store button
    if (addStoreBtn) {
        addStoreBtn.addEventListener('click', () => openStoreModal());
    }
    
    // Modal close buttons
    document.querySelectorAll('.modal-close, #cancel-btn, #cancel-store-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            closeVetModal();
            closeStoreModal();
        });
    });
    
    // Veterinarian form
    vetForm.addEventListener('submit', handleVetSubmit);
    
    // Pet store form
    if (storeForm) {
        storeForm.addEventListener('submit', handleStoreSubmit);
    }
    
    // Search and filters
    vetSearch.addEventListener('input', filterVeterinarians);
    if (storeSearch) {
        storeSearch.addEventListener('input', filterPetStores);
    }
    
    filterBtns.forEach(btn => {
        btn.addEventListener('click', (e) => {
            filterBtns.forEach(b => b.classList.remove('active'));
            e.target.classList.add('active');
            filterVeterinarians();
            filterPetStores();
        });
    });
    
    // Close modal when clicking outside
    vetModal.addEventListener('click', (e) => {
        if (e.target === vetModal) closeVetModal();
    });
    
    if (storeModal) {
        storeModal.addEventListener('click', (e) => {
            if (e.target === storeModal) closeStoreModal();
        });
    }
}

// Authentication functions
async function handleLogin(e) {
    e.preventDefault();
    
    const email = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value;
    const loginBtn = document.getElementById('login-btn');
    
    if (!email || !password) {
        showNotification('Please fill in all fields', 'error');
        return;
    }
    
    loginBtn.classList.add('loading');
    loginBtn.disabled = true;
    
    try {
        const result = await FirebaseService.signIn(email, password);
        
        if (result.success) {
            console.log('✅ Login successful');
            // Dashboard will be shown by onAuthStateChanged
        } else {
            showNotification(result.error, 'error');
        }
    } catch (error) {
        console.error('❌ Login error:', error);
        showNotification('Login failed. Please try again.', 'error');
    } finally {
        loginBtn.classList.remove('loading');
        loginBtn.disabled = false;
    }
}

async function handleLogout() {
    try {
        await FirebaseService.signOut();
        console.log('✅ Logout successful');
        
        // Clean up subscriptions
        if (unsubscribeVets) {
            unsubscribeVets();
            unsubscribeVets = null;
        }
        if (unsubscribeStores) {
            unsubscribeStores();
            unsubscribeStores = null;
        }
        
        currentUser = null;
        veterinariansData = [];
        petStoresData = [];
        
        showLogin();
    } catch (error) {
        console.error('❌ Logout error:', error);
        showNotification('Logout failed', 'error');
    }
}

// UI functions
function showLogin() {
    loadingScreen.style.display = 'none';
    loginContainer.style.display = 'flex';
    dashboardContainer.style.display = 'none';
}

function showDashboard() {
    loadingScreen.style.display = 'none';
    loginContainer.style.display = 'none';
    dashboardContainer.style.display = 'flex';
    
    // Update user info
    if (currentUser) {
        userName.textContent = currentUser.displayName || currentUser.email;
    }
}

function navigateToPage(pageName) {
    // Update navigation
    navItems.forEach(item => {
        item.classList.toggle('active', item.dataset.page === pageName);
    });
    
    // Update pages
    pages.forEach(page => {
        page.classList.toggle('active', page.id === `${pageName}-page`);
    });
    
    // Update page title
    const titles = {
        overview: 'Dashboard Overview',
        veterinarians: 'Veterinarians Management',
        stores: 'Pet Stores Management',
        users: 'Users Management',
        reports: 'Pet Reports',
        settings: 'Settings'
    };
    
    pageTitle.textContent = titles[pageName] || 'Dashboard';
    
    // Load page-specific data
    if (pageName === 'veterinarians') {
        loadVeterinarians();
    } else if (pageName === 'stores') {
        loadPetStores();
    } else if (pageName === 'users') {
        if (window.adminFeatures) {
            window.adminFeatures.loadUsers();
        }
    } else if (pageName === 'reports') {
        if (window.adminFeatures) {
            window.adminFeatures.loadReports();
        }
    } else if (pageName === 'settings') {
        if (window.adminFeatures) {
            window.adminFeatures.loadSettings();
        }
    }
}

// Dashboard data loading
async function loadDashboardData() {
    try {
        console.log('📊 Loading dashboard data...');
        
        // Load statistics
        await loadStatistics();
        
        // Load recent activity
        await loadRecentActivity();
        
        // Set up real-time listeners
        setupRealtimeListeners();
        
        console.log('✅ Dashboard data loaded');
    } catch (error) {
        console.error('❌ Error loading dashboard data:', error);
    }
}

async function loadStatistics() {
    try {
        const result = await FirebaseService.getStats();
        
        if (result.success) {
            const stats = result.data;
            totalVetsEl.textContent = stats.totalVets;
            totalUsersEl.textContent = stats.totalUsers;
            if (totalStoresEl) totalStoresEl.textContent = stats.totalStores;
            if (totalPetsEl) totalPetsEl.textContent = stats.totalReports;
            totalChatsEl.textContent = stats.totalChats;
            
            // Update additional stats if elements exist
            const activeUsersEl = document.getElementById('active-users');
            const activeStoresEl = document.getElementById('active-stores');
            const pendingReportsEl = document.getElementById('pending-reports');
            
            if (activeUsersEl) activeUsersEl.textContent = stats.activeUsers;
            if (activeStoresEl) activeStoresEl.textContent = stats.activeStores;
            if (pendingReportsEl) pendingReportsEl.textContent = stats.pendingReports;
        }
    } catch (error) {
        console.error('❌ Error loading statistics:', error);
    }
}

async function loadRecentActivity() {
    try {
        const result = await FirebaseService.getRecentActivity();
        
        if (result.success) {
            displayRecentActivity(result.data);
        }
    } catch (error) {
        console.error('❌ Error loading recent activity:', error);
    }
}

function displayRecentActivity(activities) {
    if (!recentActivityEl) return;
    
    if (activities.length === 0) {
        recentActivityEl.innerHTML = '<p class="text-center">No recent activity</p>';
        return;
    }
    
    const html = activities.map(activity => `
        <div class="activity-item">
            <div class="activity-icon ${activity.type}">
                <i class="fas ${getActivityIcon(activity.type)}"></i>
            </div>
            <div class="activity-content">
                <h4>${activity.title}</h4>
                <p>${activity.description}</p>
            </div>
        </div>
    `).join('');
    
    recentActivityEl.innerHTML = html;
}

function getActivityIcon(type) {
    switch (type) {
        case 'new': return 'fa-plus';
        case 'edit': return 'fa-edit';
        case 'delete': return 'fa-trash';
        default: return 'fa-info';
    }
}

// Real-time listeners
function setupRealtimeListeners() {
    // Listen to veterinarians changes
    unsubscribeVets = FirebaseService.onVeterinariansChange((vets) => {
        veterinariansData = vets;
        displayVeterinarians(vets);
        
        // Update statistics
        totalVetsEl.textContent = vets.length;
    });
    
    // Listen to pet stores changes
    unsubscribeStores = FirebaseService.onPetStoresChange((stores) => {
        petStoresData = stores;
        displayPetStores(stores);
        
        // Update statistics
        if (totalStoresEl) totalStoresEl.textContent = stores.length;
    });
}

// Veterinarians management
function loadVeterinarians() {
    if (veterinariansData.length > 0) {
        displayVeterinarians(veterinariansData);
    }
}

function displayVeterinarians(vets) {
    if (!vetsTableBody) return;
    
    if (vets.length === 0) {
        vetsTableBody.innerHTML = `
            <tr>
                <td colspan="6" class="text-center">No veterinarians found</td>
            </tr>
        `;
        return;
    }
    
    const html = vets.map(vet => `
        <tr>
            <td>
                <div style="display: flex; align-items: center; gap: 0.75rem;">
                    <div style="width: 40px; height: 40px; background: ${vet.isActive ? '#386641' : '#95a5a6'}; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: white;">
                        <i class="fas fa-user-md"></i>
                    </div>
                    <div>
                        <div style="font-weight: 600;">${vet.name || 'Unknown'}</div>
                        <div style="font-size: 0.8rem; color: #7f8c8d;">ID: ${vet.id.substring(0, 8)}...</div>
                    </div>
                </div>
            </td>
            <td>${vet.email || 'N/A'}</td>
            <td>${vet.specialization || 'N/A'}</td>
            <td>${vet.experience || 'N/A'}</td>
            <td>
                <span class="status-badge ${vet.isActive ? 'active' : 'inactive'}">
                    ${vet.isActive ? 'Active' : 'Inactive'}
                </span>
            </td>
            <td>
                <div class="action-buttons">
                    <button class="btn btn-small btn-secondary" onclick="editVeterinarian('${vet.id}')">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="btn btn-small ${vet.isActive ? 'btn-warning' : 'btn-success'}" onclick="toggleVetStatus('${vet.id}', ${!vet.isActive})">
                        <i class="fas ${vet.isActive ? 'fa-pause' : 'fa-play'}"></i>
                    </button>
                    <button class="btn btn-small btn-danger" onclick="deleteVeterinarian('${vet.id}')">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </td>
        </tr>
    `).join('');
    
    vetsTableBody.innerHTML = html;
}

function filterVeterinarians() {
    const searchTerm = vetSearch.value.toLowerCase();
    const activeFilter = document.querySelector('.filter-btn.active').dataset.filter;
    
    let filteredVets = veterinariansData;
    
    // Apply search filter
    if (searchTerm) {
        filteredVets = filteredVets.filter(vet => 
            (vet.name || '').toLowerCase().includes(searchTerm) ||
            (vet.email || '').toLowerCase().includes(searchTerm) ||
            (vet.specialization || '').toLowerCase().includes(searchTerm)
        );
    }
    
    // Apply status filter
    if (activeFilter !== 'all') {
        const isActive = activeFilter === 'active';
        filteredVets = filteredVets.filter(vet => vet.isActive === isActive);
    }
    
    displayVeterinarians(filteredVets);
}

// Veterinarian modal functions
function openVetModal(vet = null) {
    currentEditingVet = vet;
    
    const modalTitle = document.getElementById('modal-title');
    const passwordRow = document.getElementById('password-row');
    const vetPassword = document.getElementById('vet-password');
    
    if (vet) {
        // Edit mode
        modalTitle.textContent = 'Edit Veterinarian';
        passwordRow.style.display = 'none';
        vetPassword.required = false;
        
        // Fill form with existing data
        document.getElementById('vet-name').value = vet.name || '';
        document.getElementById('vet-email').value = vet.email || '';
        document.getElementById('vet-phone').value = vet.phone || '';
        document.getElementById('vet-specialization').value = vet.specialization || '';
        document.getElementById('vet-experience').value = vet.experience || '';
        document.getElementById('vet-license').value = vet.license || '';
    } else {
        // Add mode
        modalTitle.textContent = 'Add Veterinarian';
        passwordRow.style.display = 'block';
        vetPassword.required = true;
        
        // Clear form
        vetForm.reset();
    }
    
    vetModal.classList.add('show');
}

function closeVetModal() {
    vetModal.classList.remove('show');
    currentEditingVet = null;
    vetForm.reset();
}

async function handleVetSubmit(e) {
    e.preventDefault();
    
    const saveBtn = document.getElementById('save-vet-btn');
    saveBtn.classList.add('loading');
    saveBtn.disabled = true;
    
    try {
        const formData = {
            name: document.getElementById('vet-name').value.trim(),
            email: document.getElementById('vet-email').value.trim(),
            phone: document.getElementById('vet-phone').value.trim(),
            specialization: document.getElementById('vet-specialization').value.trim(),
            experience: document.getElementById('vet-experience').value.trim(),
            license: document.getElementById('vet-license').value.trim()
        };
        
        let result;
        
        if (currentEditingVet) {
            // Update existing veterinarian
            result = await FirebaseService.updateVeterinarian(currentEditingVet.id, formData);
        } else {
            // Create new veterinarian
            formData.password = document.getElementById('vet-password').value;
            result = await FirebaseService.createVeterinarian(formData);
        }
        
        if (result.success) {
            showNotification(
                currentEditingVet ? 'Veterinarian updated successfully!' : 'Veterinarian created successfully!',
                'success'
            );
            closeVetModal();
        } else {
            showNotification(result.error, 'error');
        }
    } catch (error) {
        console.error('❌ Error saving veterinarian:', error);
        showNotification('Failed to save veterinarian', 'error');
    } finally {
        saveBtn.classList.remove('loading');
        saveBtn.disabled = false;
    }
}

// Global functions for inline event handlers
window.editVeterinarian = function(vetId) {
    const vet = veterinariansData.find(v => v.id === vetId);
    if (vet) {
        openVetModal(vet);
    }
};

window.toggleVetStatus = async function(vetId, newStatus) {
    try {
        const result = await FirebaseService.toggleVeterinarianStatus(vetId, newStatus);
        
        if (result.success) {
            showNotification(
                `Veterinarian ${newStatus ? 'activated' : 'deactivated'} successfully!`,
                'success'
            );
        } else {
            showNotification(result.error, 'error');
        }
    } catch (error) {
        console.error('❌ Error toggling veterinarian status:', error);
        showNotification('Failed to update status', 'error');
    }
};

window.deleteVeterinarian = function(vetId) {
    const vet = veterinariansData.find(v => v.id === vetId);
    if (!vet) return;
    
    if (confirm(`Are you sure you want to delete Dr. ${vet.name}? This action cannot be undone.`)) {
        deleteVet(vetId);
    }
};

async function deleteVet(vetId) {
    try {
        const result = await FirebaseService.deleteVeterinarian(vetId);
        
        if (result.success) {
            showNotification('Veterinarian deleted successfully!', 'success');
        } else {
            showNotification(result.error, 'error');
        }
    } catch (error) {
        console.error('❌ Error deleting veterinarian:', error);
        showNotification('Failed to delete veterinarian', 'error');
    }
}

// Utility functions
function showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.innerHTML = `
        <div class="notification-content">
            <i class="fas ${getNotificationIcon(type)}"></i>
            <span>${message}</span>
        </div>
    `;
    
    // Add styles
    Object.assign(notification.style, {
        position: 'fixed',
        top: '20px',
        right: '20px',
        padding: '1rem 1.5rem',
        borderRadius: '8px',
        color: 'white',
        zIndex: '10000',
        display: 'flex',
        alignItems: 'center',
        gap: '0.5rem',
        minWidth: '300px',
        animation: 'slideInRight 0.3s ease-out',
        backgroundColor: type === 'success' ? '#27ae60' : type === 'error' ? '#e74c3c' : '#3498db'
    });
    
    document.body.appendChild(notification);
    
    // Remove after 4 seconds
    setTimeout(() => {
        notification.style.animation = 'slideOutRight 0.3s ease-out';
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 300);
    }, 4000);
}

function getNotificationIcon(type) {
    switch (type) {
        case 'success': return 'fa-check-circle';
        case 'error': return 'fa-exclamation-circle';
        case 'warning': return 'fa-exclamation-triangle';
        default: return 'fa-info-circle';
    }
}

// Add notification animations to CSS
const style = document.createElement('style');
style.textContent = `
    @keyframes slideInRight {
        from { transform: translateX(100%); opacity: 0; }
        to { transform: translateX(0); opacity: 1; }
    }
    
    @keyframes slideOutRight {
        from { transform: translateX(0); opacity: 1; }
        to { transform: translateX(100%); opacity: 0; }
    }
    
    .notification-content {
        display: flex;
        align-items: center;
        gap: 0.5rem;
    }
    
    .btn-warning {
        background: #f39c12;
        color: white;
    }
    
    .btn-warning:hover {
        background: #d68910;
    }
    
    .btn-success {
        background: #27ae60;
        color: white;
    }
    
    .btn-success:hover {
        background: #229954;
    }
    
    .text-center {
        text-align: center;
        padding: 2rem;
        color: #7f8c8d;
    }
`;
document.head.appendChild(style);

// Pet Stores management
function loadPetStores() {
    if (petStoresData.length > 0) {
        displayPetStores(petStoresData);
    }
}

function displayPetStores(stores) {
    if (!storesGrid) return;
    
    if (stores.length === 0) {
        storesGrid.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-store"></i>
                <h3>No Pet Stores Found</h3>
                <p>Start by adding your first pet store to the platform.</p>
                <button class="btn btn-primary" onclick="openStoreModal()">
                    <i class="fas fa-plus"></i>
                    Add Pet Store
                </button>
            </div>
        `;
        return;
    }
    
    const html = stores.map(store => `
        <div class="store-card">
            <div class="store-image">
                ${store.imageUrl ? 
                    `<img src="${store.imageUrl}" alt="${store.name}" onerror="this.style.display='none'">` : 
                    `<i class="fas fa-store"></i>`
                }
                <div class="store-status ${store.isActive ? 'active' : 'inactive'}">
                    ${store.isActive ? 'Active' : 'Inactive'}
                </div>
            </div>
            <div class="store-content">
                <div class="store-header">
                    <div>
                        <div class="store-title">${store.name || 'Unknown Store'}</div>
                        <div class="store-rating">
                            ${generateStars(store.rating || 4.0)}
                            <span>${(store.rating || 4.0).toFixed(1)}</span>
                        </div>
                    </div>
                    <div class="store-category category-${store.category || 'general'}">
                        ${formatCategory(store.category)}
                    </div>
                </div>
                
                <div class="store-info">
                    <div><i class="fas fa-map-marker-alt"></i> ${store.city || 'Unknown City'}</div>
                    <div><i class="fas fa-phone"></i> ${store.phone || 'N/A'}</div>
                    ${store.workingHours ? `<div><i class="fas fa-clock"></i> ${store.workingHours}</div>` : ''}
                    ${store.email ? `<div><i class="fas fa-envelope"></i> ${store.email}</div>` : ''}
                </div>
                
                ${store.description ? `
                    <p style="color: #7f8c8d; font-size: 0.9rem; margin: 1rem 0; line-height: 1.4;">
                        ${store.description.length > 100 ? store.description.substring(0, 100) + '...' : store.description}
                    </p>
                ` : ''}
                
                <div class="store-tags">
                    ${store.deliveryAvailable ? '<span class="store-tag">Delivery Available</span>' : ''}
                    ${store.website ? '<span class="store-tag">Website</span>' : ''}
                </div>
                
                <div class="store-actions">
                    <button class="btn btn-small btn-secondary" onclick="editPetStore('${store.id}')">
                        <i class="fas fa-edit"></i>
                        Edit
                    </button>
                    <button class="btn btn-small ${store.isActive ? 'btn-warning' : 'btn-success'}" onclick="toggleStoreStatus('${store.id}', ${!store.isActive})">
                        <i class="fas ${store.isActive ? 'fa-pause' : 'fa-play'}"></i>
                        ${store.isActive ? 'Deactivate' : 'Activate'}
                    </button>
                    <button class="btn btn-small btn-danger" onclick="deletePetStore('${store.id}')">
                        <i class="fas fa-trash"></i>
                        Delete
                    </button>
                </div>
            </div>
        </div>
    `).join('');
    
    storesGrid.innerHTML = html;
}

function generateStars(rating) {
    const fullStars = Math.floor(rating);
    const hasHalfStar = rating % 1 >= 0.5;
    const emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
    
    let stars = '';
    for (let i = 0; i < fullStars; i++) {
        stars += '<i class="fas fa-star"></i>';
    }
    if (hasHalfStar) {
        stars += '<i class="fas fa-star-half-alt"></i>';
    }
    for (let i = 0; i < emptyStars; i++) {
        stars += '<i class="far fa-star"></i>';
    }
    
    return stars;
}

function formatCategory(category) {
    if (!category) return 'General';
    return category.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
}

function filterPetStores() {
    if (!storeSearch || !petStoresData) return;
    
    const searchTerm = storeSearch.value.toLowerCase();
    const activeFilter = document.querySelector('.filter-btn.active')?.dataset.filter || 'all';
    
    let filteredStores = petStoresData;
    
    // Apply search filter
    if (searchTerm) {
        filteredStores = filteredStores.filter(store => 
            (store.name || '').toLowerCase().includes(searchTerm) ||
            (store.category || '').toLowerCase().includes(searchTerm) ||
            (store.city || '').toLowerCase().includes(searchTerm) ||
            (store.description || '').toLowerCase().includes(searchTerm)
        );
    }
    
    // Apply status filter
    if (activeFilter !== 'all') {
        const isActive = activeFilter === 'active';
        filteredStores = filteredStores.filter(store => store.isActive === isActive);
    }
    
    displayPetStores(filteredStores);
}

// Pet Store modal functions
function openStoreModal(store = null) {
    currentEditingStore = store;
    
    const modalTitle = document.getElementById('store-modal-title');
    
    if (store) {
        // Edit mode
        modalTitle.textContent = 'Edit Pet Store';
        
        // Fill form with existing data
        document.getElementById('store-name').value = store.name || '';
        document.getElementById('store-category').value = store.category || '';
        document.getElementById('store-phone').value = store.phone || '';
        document.getElementById('store-email').value = store.email || '';
        document.getElementById('store-address').value = store.address || '';
        document.getElementById('store-city').value = store.city || '';
        document.getElementById('store-website').value = store.website || '';
        document.getElementById('store-hours').value = store.workingHours || '';
        document.getElementById('store-delivery').value = store.deliveryAvailable ? 'true' : 'false';
        document.getElementById('store-description').value = store.description || '';
        document.getElementById('store-image').value = store.imageUrl || '';
        document.getElementById('store-rating').value = store.rating || 4.0;
    } else {
        // Add mode
        modalTitle.textContent = 'Add Pet Store';
        
        // Clear form
        storeForm.reset();
        document.getElementById('store-delivery').value = 'true';
        document.getElementById('store-rating').value = '4.0';
    }
    
    storeModal.classList.add('show');
}

function closeStoreModal() {
    if (storeModal) {
        storeModal.classList.remove('show');
    }
    currentEditingStore = null;
    if (storeForm) {
        storeForm.reset();
    }
}

async function handleStoreSubmit(e) {
    e.preventDefault();
    
    const saveBtn = document.getElementById('save-store-btn');
    saveBtn.classList.add('loading');
    saveBtn.disabled = true;
    
    try {
        const formData = {
            name: document.getElementById('store-name').value.trim(),
            category: document.getElementById('store-category').value,
            phone: document.getElementById('store-phone').value.trim(),
            email: document.getElementById('store-email').value.trim(),
            address: document.getElementById('store-address').value.trim(),
            city: document.getElementById('store-city').value.trim(),
            website: document.getElementById('store-website').value.trim(),
            workingHours: document.getElementById('store-hours').value.trim(),
            deliveryAvailable: document.getElementById('store-delivery').value,
            description: document.getElementById('store-description').value.trim(),
            imageUrl: document.getElementById('store-image').value.trim(),
            rating: document.getElementById('store-rating').value
        };
        
        let result;
        
        if (currentEditingStore) {
            // Update existing store
            result = await FirebaseService.updatePetStore(currentEditingStore.id, formData);
        } else {
            // Create new store
            result = await FirebaseService.createPetStore(formData);
        }
        
        if (result.success) {
            showNotification(
                currentEditingStore ? 'Pet store updated successfully!' : 'Pet store created successfully!',
                'success'
            );
            closeStoreModal();
        } else {
            showNotification(result.error, 'error');
        }
    } catch (error) {
        console.error('❌ Error saving pet store:', error);
        showNotification('Failed to save pet store', 'error');
    } finally {
        saveBtn.classList.remove('loading');
        saveBtn.disabled = false;
    }
}

// Global functions for inline event handlers
window.editPetStore = function(storeId) {
    const store = petStoresData.find(s => s.id === storeId);
    if (store) {
        openStoreModal(store);
    }
};

window.toggleStoreStatus = async function(storeId, newStatus) {
    try {
        const result = await FirebaseService.togglePetStoreStatus(storeId, newStatus);
        
        if (result.success) {
            showNotification(
                `Pet store ${newStatus ? 'activated' : 'deactivated'} successfully!`,
                'success'
            );
        } else {
            showNotification(result.error, 'error');
        }
    } catch (error) {
        console.error('❌ Error toggling pet store status:', error);
        showNotification('Failed to update status', 'error');
    }
};

window.deletePetStore = function(storeId) {
    const store = petStoresData.find(s => s.id === storeId);
    if (!store) return;
    
    if (confirm(`Are you sure you want to delete "${store.name}"? This action cannot be undone.`)) {
        deleteStore(storeId);
    }
};

async function deleteStore(storeId) {
    try {
        const result = await FirebaseService.deletePetStore(storeId);
        
        if (result.success) {
            showNotification('Pet store deleted successfully!', 'success');
        } else {
            showNotification(result.error, 'error');
        }
    } catch (error) {
        console.error('❌ Error deleting pet store:', error);
        showNotification('Failed to delete pet store', 'error');
    }
}

console.log('✅ Admin Dashboard initialized successfully!'); 