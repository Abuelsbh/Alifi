// Global variables
let currentUser = null;
let veterinariansData = [];
let petStoresData = [];
let usersData = []; // Added for users data
let reportsData = []; // Added for reports data
let unsubscribeVets = null;
let unsubscribeStores = null;
let currentEditingVet = null;
let currentEditingStore = null;
let isCreatingVet = false; // Flag to track veterinarian creation
let adminUserBeforeVetCreation = null; // Store admin user before creating vet

// Admin management (Added)
const addAdminBtn = document.getElementById('add-admin-btn');
const addAdminModal = document.getElementById('add-admin-modal');
const addAdminForm = document.getElementById('add-admin-form');
const adminSearch = document.getElementById('admin-search');
const adminsTableBody = document.getElementById('admins-table-body');

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

// Users elements (Added)
const exportUsersBtn = document.getElementById('export-users-btn');
const userSearch = document.getElementById('user-search');
const usersTableBody = document.getElementById('users-table-body');
const userFilterBtns = document.querySelectorAll('#users-page .filter-btn');

// Reports elements (Added)
const exportReportsBtn = document.getElementById('export-reports-btn');
const reportSearch = document.getElementById('report-search');
const reportsGrid = document.getElementById('reports-grid');
const reportFilterBtns = document.querySelectorAll('#reports-page .filter-btn');

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
        FirebaseService.onAuthStateChanged(async (user) => {
            // Ignore auth state changes during veterinarian creation
            if (isCreatingVet) {
                console.log('⏳ Ignoring auth state change during vet creation');
                return;
            }
            
            if (user) {
                console.log('✅ User authenticated:', user.email);
                // Check for admin status from Firestore instead of custom claims
                const isAdmin = await FirebaseService.checkAdminStatus(user.uid);
                if (isAdmin) {
                    currentUser = user;
                    showDashboard();
                    loadDashboardData();
                } else {
                    console.warn('❌ Non-admin user attempted login:', user.email);
                    await FirebaseService.signOut(); // Force logout non-admin
                    showNotification('Access Denied: Only administrators can log in.', 'error');
                    showLogin();
                }
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

    // Ensure Admins page and modal are within main content
    const mainContent = document.querySelector('main.content');
    const adminsPage = document.getElementById('admins-page');
    const addAdminModal = document.getElementById('add-admin-modal');

    if (mainContent && adminsPage && adminsPage.parentNode !== mainContent) {
        adminsPage.parentNode.removeChild(adminsPage);
        mainContent.appendChild(adminsPage);
    }
    if (mainContent && addAdminModal && addAdminModal.parentNode !== mainContent) {
        addAdminModal.parentNode.removeChild(addAdminModal);
        mainContent.appendChild(addAdminModal);
    }
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
    if (addVetBtn) { // Added null check
        addVetBtn.addEventListener('click', () => openVetModal());
    }
    
    // Add pet store button
    if (addStoreBtn) {
        addStoreBtn.addEventListener('click', () => openStoreModal(null));
    }
    
    // Add Admin button (Added)
    if (addAdminBtn) {
        addAdminBtn.addEventListener('click', () => adminFeatures.openAddAdminModal());
    }

    // Locations elements
    const addLocationBtn = document.getElementById('add-location-btn');
    const locationModal = document.getElementById('location-modal');
    const locationForm = document.getElementById('location-form');
    const locationSearch = document.getElementById('location-search');
    const locationsTableBody = document.getElementById('locations-table-body');

    // Add Location button
    if (addLocationBtn) {
        addLocationBtn.addEventListener('click', () => openLocationModal());
    }

    // Location form submission
    if (locationForm) {
        locationForm.addEventListener('submit', handleLocationSubmit);
    }

    // Cancel Location button
    const cancelLocationBtn = document.getElementById('cancel-location-btn');
    if (cancelLocationBtn) {
        cancelLocationBtn.addEventListener('click', () => closeLocationModal());
    }

    // Search for Locations
    if (locationSearch) {
        locationSearch.addEventListener('input', (e) => filterLocations(e.target.value));
    }

    // Admin form submission (Added)
    if (addAdminForm) {
        addAdminForm.addEventListener('submit', (e) => {
            e.preventDefault();
            adminFeatures.handleAddAdminSubmit();
        });
    }

    // Cancel Add Admin button (Added)
    const cancelAddAdminBtn = document.getElementById('cancel-add-admin-btn');
    if (cancelAddAdminBtn) {
        cancelAddAdminBtn.addEventListener('click', () => adminFeatures.closeModal('add-admin-modal'));
    }

    // Search for Admins (Added)
    if (adminSearch) {
        adminSearch.addEventListener('input', (e) => adminFeatures.filterAdmins(e.target.value));
    }

    // Modal close buttons
    document.querySelectorAll('.modal-close, #cancel-btn, #cancel-store-btn, #cancel-location-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            closeVetModal();
            closeStoreModal();
            closeLocationModal();
            // Close user and report modals (Added)
            if (document.getElementById('user-modal')) adminFeatures.closeModal('user-modal');
            if (document.getElementById('report-modal')) adminFeatures.closeModal('report-modal');
            if (document.getElementById('send-message-modal')) adminFeatures.closeModal('send-message-modal');
            if (document.getElementById('add-admin-modal')) adminFeatures.closeModal('add-admin-modal'); // Added
        });
    });
    
    // Veterinarian form
    if (vetForm) { // Added null check
        vetForm.addEventListener('submit', handleVetSubmit);
    }
    
    // Pet store form
    if (storeForm) {
        storeForm.addEventListener('submit', handleStoreSubmit);
        
        // Add image preview functionality
        const storeImageInput = document.getElementById('store-image');
        if (storeImageInput) {
            storeImageInput.addEventListener('change', function(e) {
                const file = e.target.files[0];
                const preview = document.getElementById('store-image-preview');
                const previewImg = document.getElementById('store-image-preview-img');
                
                if (file) {
                    const reader = new FileReader();
                    reader.onload = function(e) {
                        previewImg.src = e.target.result;
                        preview.style.display = 'block';
                    };
                    reader.readAsDataURL(file);
                } else {
                    preview.style.display = 'none';
                }
            });
        }
        
        // Add working hours closed checkbox functionality
        const days = ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
        days.forEach(day => {
            const checkbox = document.getElementById(`store-hours-${day}-closed`);
            const input = document.getElementById(`store-hours-${day}`);
            
            if (checkbox && input) {
                checkbox.addEventListener('change', function() {
                    if (this.checked) {
                        input.disabled = true;
                        input.value = '';
                        input.placeholder = 'Closed';
                    } else {
                        input.disabled = false;
                        input.placeholder = '9:00 AM - 10:00 PM';
                    }
                });
            }
        });
    }
    
    // Search and filters for Veterinarians
    if (vetSearch) { // Added null check
        vetSearch.addEventListener('input', filterVeterinarians);
    }

    // Search and filters for Pet Stores
    if (storeSearch) {
        storeSearch.addEventListener('input', filterPetStores);
    }

    filterBtns.forEach(btn => { // These are the general filter buttons, need to be more specific
        btn.addEventListener('click', (e) => {
            filterBtns.forEach(b => b.classList.remove('active'));
            e.target.classList.add('active');
            filterVeterinarians();
            filterPetStores();
            // User and Report filters are handled in admin-features.js
        });
    });
    
    // User page event listeners (Added)
    if (exportUsersBtn) {
        exportUsersBtn.addEventListener('click', () => window.adminFeatures.exportUsers());
    }
    if (userSearch) {
        userSearch.addEventListener('input', (e) => window.adminFeatures.filterUsers(e.target.value));
    }
    userFilterBtns.forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.preventDefault();
            userFilterBtns.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            window.adminFeatures.filterUsersByStatus(btn.dataset.filter);
        });
    });

    // Report page event listeners (Added)
    if (exportReportsBtn) {
        exportReportsBtn.addEventListener('click', () => window.adminFeatures.exportReports());
    }
    if (reportSearch) {
        reportSearch.addEventListener('input', (e) => window.adminFeatures.filterReports(e.target.value));
    }
    reportFilterBtns.forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.preventDefault();
            reportFilterBtns.forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            window.adminFeatures.filterReportsByType(btn.dataset.filter);
        });
    });

    // Close modal when clicking outside
    if (vetModal) { // Added null check
        vetModal.addEventListener('click', (e) => {
            if (e.target === vetModal) closeVetModal();
        });
    }
    
    if (storeModal) {
        storeModal.addEventListener('click', (e) => {
            if (e.target === storeModal) closeStoreModal();
        });
    }

    // User modal close outside (Added)
    const userModal = document.getElementById('user-modal');
    if (userModal) {
        userModal.addEventListener('click', (e) => {
            if (e.target === userModal) adminFeatures.closeModal('user-modal');
        });
    }

    // Report modal close outside (Added)
    const reportModal = document.getElementById('report-modal');
    if (reportModal) {
        reportModal.addEventListener('click', (e) => {
            if (e.target === reportModal) adminFeatures.closeModal('report-modal');
        });
    }

    // Send message modal close outside (Added)
    const sendMessageModal = document.getElementById('send-message-modal');
    if (sendMessageModal) {
        sendMessageModal.addEventListener('click', (e) => {
            if (e.target === sendMessageModal) adminFeatures.closeModal('send-message-modal');
        });
    }

    // Add Admin modal close outside (Added)
    if (addAdminModal) {
        addAdminModal.addEventListener('click', (e) => {
            if (e.target === addAdminModal) adminFeatures.closeModal('add-admin-modal');
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
    
    // Store credentials temporarily in sessionStorage for vet creation restoration
    // This is only used to restore admin session after creating a veterinarian
    sessionStorage.setItem('tempAdminEmail', email);
    sessionStorage.setItem('tempAdminPassword', password);
    
    loginBtn.classList.add('loading');
    loginBtn.disabled = true;
    loginBtn.textContent = 'Logging in...';
    
    try {
        console.log('🚀 Starting login process...');
        const result = await FirebaseService.signIn(email, password);
        
        if (result.success) {
            console.log('✅ Login successful, checking admin status...');
            loginBtn.textContent = 'Checking permissions...';
            // Dashboard will be shown by onAuthStateChanged
        } else {
            console.error('❌ Login failed:', result.error);
            showNotification(result.error || 'Login failed. Please try again.', 'error');
            loginBtn.textContent = 'Login';
            // Clear stored credentials on login failure
            sessionStorage.removeItem('tempAdminEmail');
            sessionStorage.removeItem('tempAdminPassword');
        }
    } catch (error) {
        console.error('❌ Login error:', error);
        showNotification('Login failed. Please try again.', 'error');
        loginBtn.textContent = 'Login';
        // Clear stored credentials on error
        sessionStorage.removeItem('tempAdminEmail');
        sessionStorage.removeItem('tempAdminPassword');
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
        
        // Clear stored admin credentials
        sessionStorage.removeItem('tempAdminEmail');
        sessionStorage.removeItem('tempAdminPassword');
        
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
    
    // Default to overview page on dashboard load
    navigateToPage('overview');
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
        reports: 'Pet Reports Management', // Changed 'Pet Reports' to 'Pet Reports Management' for consistency
        advertisements: 'Advertisements Management',
        locations: 'Locations Management',
        admins: 'Admins Management', // Added for Admins page
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
        } else {
            console.error('adminFeatures not available when navigating to users'); // Added error log
        }
    } else if (pageName === 'reports') {
        if (window.adminFeatures) {
            window.adminFeatures.loadReports();
        } else {
            console.error('adminFeatures not available when navigating to reports'); // Added error log
        }
    } else if (pageName === 'advertisements') {
        console.log('Navigating to advertisements page...');
        if (window.adminFeatures) {
            console.log('Loading advertisements...');
            window.adminFeatures.loadAds();
        } else {
            console.error('adminFeatures not available when navigating to advertisements');
        }
    } else if (pageName === 'locations') {
        loadLocations();
    } else if (pageName === 'admins') { // Added for Admins page
        if (window.adminFeatures) {
            window.adminFeatures.loadAdmins();
        } else {
            console.error('adminFeatures not available when navigating to admins');
        }
    } else if (pageName === 'settings') {
        if (window.adminFeatures) {
            window.adminFeatures.loadSettings();
        } else {
            console.error('adminFeatures not available when navigating to settings'); // Added error log
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
            const adminEmail = currentUser?.email;
            const adminPassword = sessionStorage.getItem('tempAdminPassword');
            
            // Set flag to prevent auth state change handler from interfering
            // This flag will prevent showing error messages during the creation process
            isCreatingVet = true;
            
            formData.password = document.getElementById('vet-password').value;
            
            try {
                // Create veterinarian - this function will handle sign out and sign back in automatically
                result = await FirebaseService.createVeterinarian(formData, adminEmail, adminPassword);
                
                // Wait a bit to ensure auth state has stabilized
                await new Promise(resolve => setTimeout(resolve, 300));
                
                // Reset the flag after creation and sign-in are complete
                isCreatingVet = false;
                
                // Show success message and close modal
                if (result.success) {
                    showNotification('Veterinarian created successfully!', 'success');
                    closeVetModal();
                    // Reload veterinarians list to show the new one
                    loadVeterinarians();
                } else {
                    showNotification(result.error || 'Failed to create veterinarian', 'error');
                }
            } catch (error) {
                // Reset flag on error
                isCreatingVet = false;
                console.error('Error in handleVetSubmit:', error);
                showNotification('Failed to create veterinarian', 'error');
            }
        }
    } catch (error) {
        console.error('❌ Error saving veterinarian:', error);
        showNotification('Failed to save veterinarian', 'error');
        isCreatingVet = false; // Reset flag on error
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
                    ${store.workingHours ? `<div><i class="fas fa-clock"></i> ${formatWorkingHours(store.workingHours)}</div>` : ''}
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
async function openStoreModal(store = null) {
    currentEditingStore = store;
    
    const modalTitle = document.getElementById('store-modal-title');
    const imageInput = document.getElementById('store-image');
    const imagePreview = document.getElementById('store-image-preview');
    const imagePreviewImg = document.getElementById('store-image-preview-img');
    
    // Load locations
    await loadStoreLocations();
    
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
        
        // Load working hours for each day
        const workingHours = store.workingHours || {};
        if (typeof workingHours === 'string') {
            // Legacy format: single string, apply to all days
            const days = ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
            days.forEach(day => {
                const input = document.getElementById(`store-hours-${day}`);
                const checkbox = document.getElementById(`store-hours-${day}-closed`);
                if (input) {
                    input.value = workingHours;
                    input.disabled = false;
                    input.placeholder = '9:00 AM - 10:00 PM';
                }
                if (checkbox) {
                    checkbox.checked = false;
                }
            });
        } else {
            // New format: object with days
            const days = ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
            days.forEach(day => {
                const dayHours = workingHours[day];
                const input = document.getElementById(`store-hours-${day}`);
                const checkbox = document.getElementById(`store-hours-${day}-closed`);
                
                if (dayHours && dayHours.closed) {
                    if (input) {
                        input.value = '';
                        input.disabled = true;
                        input.placeholder = 'Closed';
                    }
                    if (checkbox) {
                        checkbox.checked = true;
                    }
                } else if (dayHours && dayHours.hours) {
                    if (input) {
                        input.value = dayHours.hours;
                        input.disabled = false;
                        input.placeholder = '9:00 AM - 10:00 PM';
                    }
                    if (checkbox) {
                        checkbox.checked = false;
                    }
                } else {
                    if (input) {
                        input.value = '';
                        input.disabled = false;
                        input.placeholder = '9:00 AM - 10:00 PM';
                    }
                    if (checkbox) {
                        checkbox.checked = false;
                    }
                }
            });
        }
        
        document.getElementById('store-delivery').value = store.deliveryAvailable ? 'true' : 'false';
        document.getElementById('store-description').value = store.description || '';
        document.getElementById('store-rating').value = store.rating || 4.0;
        
        // Show existing image preview
        if (store.imageUrl) {
            imagePreviewImg.src = store.imageUrl;
            imagePreview.style.display = 'block';
        } else {
            imagePreview.style.display = 'none';
        }
        
        // Clear file input (user can select new image if needed)
        imageInput.value = '';
        imageInput.required = false; // Not required when editing
    } else {
        // Add mode
        modalTitle.textContent = 'Add Pet Store';
        
        // Clear form
        storeForm.reset();
        document.getElementById('store-delivery').value = 'true';
        document.getElementById('store-rating').value = '4.0';
        imagePreview.style.display = 'none';
        imageInput.required = true; // Required when adding
        
        // Clear working hours
        const days = ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
        days.forEach(day => {
            const input = document.getElementById(`store-hours-${day}`);
            const checkbox = document.getElementById(`store-hours-${day}-closed`);
            if (input) {
                input.value = '';
                input.disabled = false;
                input.placeholder = '9:00 AM - 10:00 PM';
            }
            if (checkbox) {
                checkbox.checked = false;
            }
        });
        
        // Reset locations to "all"
        document.getElementById('store-location-all').checked = true;
        toggleStoreLocationCheckboxes(false);
    }
    
    storeModal.classList.add('show');
}

// Load locations for store form
async function loadStoreLocations() {
    try {
        const result = await FirebaseService.getAllLocations();
        if (result.success && result.data) {
            const locationsList = document.getElementById('store-locations-list');
            if (!locationsList) return;
            
            locationsList.innerHTML = result.data
                .filter(loc => loc.isActive !== false)
                .map(loc => `
                    <div style="margin-bottom: 8px;">
                        <label class="checkbox-label">
                            <input type="checkbox" class="store-location-checkbox" value="${loc.id}" data-location-name="${loc.name}">
                            <span class="checkmark"></span>
                            ${loc.name}
                        </label>
                    </div>
                `).join('');
        }
    } catch (error) {
        console.error('Error loading locations:', error);
        const locationsList = document.getElementById('store-locations-list');
        if (locationsList) {
            locationsList.innerHTML = '<p style="color: #f44336;">Failed to load locations</p>';
        }
    }
}

function toggleStoreLocationCheckboxes(disabled) {
    const checkboxes = document.querySelectorAll('.store-location-checkbox');
    checkboxes.forEach(cb => cb.disabled = disabled);
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
        const imageInput = document.getElementById('store-image');
        let imageUrl = currentEditingStore ? currentEditingStore.imageUrl : '';
        
        // Upload image if a new file is selected
        if (imageInput.files && imageInput.files.length > 0) {
            const file = imageInput.files[0];
            saveBtn.textContent = 'Uploading image...';
            
            const uploadResult = await FirebaseService.uploadImage(file, 'store_images');
            if (uploadResult.success) {
                imageUrl = uploadResult.url;
            } else {
                showNotification('Failed to upload image: ' + uploadResult.error, 'error');
                saveBtn.classList.remove('loading');
                saveBtn.disabled = false;
                return;
            }
        } else if (!currentEditingStore && !imageUrl) {
            // New store must have an image
            showNotification('Please select an image for the store', 'error');
            saveBtn.classList.remove('loading');
            saveBtn.disabled = false;
            return;
        }
        
        // Collect working hours for each day
        const workingHours = {};
        const days = ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
        days.forEach(day => {
            const closed = document.getElementById(`store-hours-${day}-closed`).checked;
            const hours = document.getElementById(`store-hours-${day}`).value.trim();
            
            if (closed) {
                workingHours[day] = { closed: true };
            } else if (hours) {
                workingHours[day] = { hours: hours, closed: false };
            } else {
                workingHours[day] = { closed: false };
            }
        });
        
        // Get selected locations
        const allLocationsChecked = document.getElementById('store-location-all').checked;
        let locations = [];
        if (allLocationsChecked) {
            locations = ['all'];
        } else {
            const selectedCheckboxes = document.querySelectorAll('.store-location-checkbox:checked');
            locations = Array.from(selectedCheckboxes).map(cb => cb.value);
            if (locations.length === 0) {
                showNotification('Please select at least one location or "All Locations"', 'error');
                saveBtn.classList.remove('loading');
                saveBtn.disabled = false;
                return;
            }
        }
        
        const formData = {
            name: document.getElementById('store-name').value.trim(),
            category: document.getElementById('store-category').value,
            phone: document.getElementById('store-phone').value.trim(),
            email: document.getElementById('store-email').value.trim(),
            address: document.getElementById('store-address').value.trim(),
            city: document.getElementById('store-city').value.trim(),
            website: document.getElementById('store-website').value.trim(),
            workingHours: workingHours,
            deliveryAvailable: document.getElementById('store-delivery').value,
            description: document.getElementById('store-description').value.trim(),
            imageUrl: imageUrl,
            rating: document.getElementById('store-rating').value,
            locations: locations
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
        saveBtn.textContent = 'Save Store';
    }
}

// Global functions for inline event handlers
window.editPetStore = async function(storeId) {
    const store = petStoresData.find(s => s.id === storeId);
    if (store) {
        await openStoreModal(store);
    }
};

// Function to copy Saturday hours to all days
// Function to format working hours for display
function formatWorkingHours(workingHours) {
    if (!workingHours) return '';
    
    // Legacy format: string
    if (typeof workingHours === 'string') {
        return workingHours;
    }
    
    // New format: object with days
    const dayNames = {
        saturday: 'Sat',
        sunday: 'Sun',
        monday: 'Mon',
        tuesday: 'Tue',
        wednesday: 'Wed',
        thursday: 'Thu',
        friday: 'Fri'
    };
    
    const days = ['saturday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
    const formattedDays = days.map(day => {
        const dayHours = workingHours[day];
        if (!dayHours) return null;
        
        if (dayHours.closed) {
            return `${dayNames[day]}: Closed`;
        } else if (dayHours.hours) {
            return `${dayNames[day]}: ${dayHours.hours}`;
        }
        return null;
    }).filter(Boolean);
    
    if (formattedDays.length === 0) return '';
    if (formattedDays.length <= 2) return formattedDays.join(', ');
    return formattedDays.slice(0, 2).join(', ') + '...';
}

// Function to copy Saturday hours to all days
function copyWorkingHoursToAll() {
    const saturdayHours = document.getElementById('store-hours-saturday').value;
    const saturdayClosed = document.getElementById('store-hours-saturday-closed').checked;
    
    const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
    days.forEach(day => {
        const input = document.getElementById(`store-hours-${day}`);
        const checkbox = document.getElementById(`store-hours-${day}-closed`);
        
        if (input) {
            input.value = saturdayHours;
            input.disabled = saturdayClosed;
            input.placeholder = saturdayClosed ? 'Closed' : '9:00 AM - 10:00 PM';
        }
        if (checkbox) {
            checkbox.checked = saturdayClosed;
        }
    });
    
    showNotification('Working hours copied to all days', 'success');
}

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
// Advertisements Event Listeners
document.addEventListener('DOMContentLoaded', () => {
    console.log('DOM loaded, initializing ad event listeners...');
    
    // Wait for adminFeatures to be available
    const initAdEventListeners = () => {
        console.log('Checking for adminFeatures...', window.adminFeatures);
        
        if (window.adminFeatures) {
            console.log('adminFeatures found, setting up event listeners...');
            
            // Add Advertisement button
            const addBtn = document.getElementById('add-ad-btn');
            console.log('Add button found:', addBtn);
            
            if (addBtn) {
                addBtn.addEventListener('click', () => {
                    console.log('Add advertisement button clicked!');
                    adminFeatures.showAddAdModal();
                });
            }

            // Advertisement form submission
            // Add image preview functionality for ads
            const adImageInput = document.getElementById('ad-image-url');
            if (adImageInput) {
                adImageInput.addEventListener('change', function(e) {
                    const file = e.target.files[0];
                    const preview = document.getElementById('ad-image-preview');
                    const previewImg = document.getElementById('ad-image-preview-img');
                    
                    if (file) {
                        const reader = new FileReader();
                        reader.onload = function(e) {
                            previewImg.src = e.target.result;
                            preview.style.display = 'block';
                        };
                        reader.readAsDataURL(file);
                    } else {
                        preview.style.display = 'none';
                    }
                });
            }
            
            document.getElementById('ad-form')?.addEventListener('submit', (e) => {
                e.preventDefault();
                console.log('Ad form submitted!');
                adminFeatures.saveAd();
            });

            // Cancel advertisement form
            document.getElementById('cancel-ad-btn')?.addEventListener('click', () => {
                adminFeatures.closeModal('ad-modal');
            });

            // Close advertisement modal
            document.getElementById('close-ad-modal')?.addEventListener('click', () => {
                adminFeatures.closeModal('ad-modal');
            });

            // Close preview modal
            document.getElementById('close-ad-preview-modal')?.addEventListener('click', () => {
                adminFeatures.closeModal('ad-preview-modal');
            });

            document.getElementById('close-preview-btn')?.addEventListener('click', () => {
                adminFeatures.closeModal('ad-preview-modal');
            });

            // Edit from preview modal
            document.getElementById('edit-ad-from-preview-btn')?.addEventListener('click', () => {
                const adId = document.getElementById('edit-ad-from-preview-btn').dataset.adId;
                adminFeatures.closeModal('ad-preview-modal');
                adminFeatures.editAd(adId);
            });
            
            console.log('Ad event listeners set up successfully!');
        } else {
            console.log('adminFeatures not found, retrying...');
            // Retry after a short delay
            setTimeout(initAdEventListeners, 100);
        }
    };
    
    initAdEventListeners();
});

// Load advertisements when advertisements page is shown
function loadAdvertisementsPage() {
    console.log('📢 Loading advertisements page...');
    adminFeatures.loadAds();
}

console.log('✅ Advertisements module initialized!');

// Locations Management Functions
let locationsData = [];
let currentEditingLocation = null;

// Make locationsData globally accessible
window.locationsData = locationsData;

function openLocationModal(location = null) {
    currentEditingLocation = location;
    const modal = document.getElementById('location-modal');
    const form = document.getElementById('location-form');
    const title = document.getElementById('location-modal-title');
    
    if (location) {
        title.textContent = 'Edit Location';
        document.getElementById('location-name').value = location.name || '';
        document.getElementById('location-description').value = location.description || '';
        document.getElementById('location-display-order').value = location.displayOrder || 0;
        document.getElementById('location-is-active').checked = location.isActive !== false;
        form.dataset.mode = 'edit';
        form.dataset.locationId = location.id;
    } else {
        title.textContent = 'Add Location';
        form.reset();
        form.dataset.mode = 'add';
        delete form.dataset.locationId;
    }
    
    modal.classList.add('show');
    document.body.style.overflow = 'hidden';
}

function closeLocationModal() {
    const modal = document.getElementById('location-modal');
    modal.classList.remove('show');
    document.body.style.overflow = 'auto';
    currentEditingLocation = null;
    const form = document.getElementById('location-form');
    form.reset();
    delete form.dataset.mode;
    delete form.dataset.locationId;
}

async function handleLocationSubmit(e) {
    e.preventDefault();
    
    const form = document.getElementById('location-form');
    const mode = form.dataset.mode;
    const locationId = form.dataset.locationId;
    
    const locationData = {
        name: document.getElementById('location-name').value.trim(),
        description: document.getElementById('location-description').value.trim(),
        displayOrder: parseInt(document.getElementById('location-display-order').value) || 0,
        isActive: document.getElementById('location-is-active').checked
    };
    
    // Validate
    if (!locationData.name) {
        alert('Location name is required');
        return;
    }
    
    // Show loading
    const submitBtn = form.querySelector('button[type="submit"]');
    const originalText = submitBtn.innerHTML;
    submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Saving...';
    submitBtn.disabled = true;
    
    try {
        let result;
        if (mode === 'edit' && locationId) {
            result = await FirebaseService.updateLocation(locationId, locationData);
        } else {
            result = await FirebaseService.createLocation(locationData);
        }
        
        if (result.success) {
            alert(`Location ${mode === 'edit' ? 'updated' : 'created'} successfully!`);
            closeLocationModal();
            loadLocations(); // Refresh the list
        } else {
            alert(result.error || `Failed to ${mode === 'edit' ? 'update' : 'create'} location`);
        }
    } catch (error) {
        console.error('Error saving location:', error);
        alert('Failed to save location: ' + error.message);
    } finally {
        submitBtn.innerHTML = originalText;
        submitBtn.disabled = false;
    }
}

async function loadLocations() {
    console.log('🔄 Loading locations...');
    try {
        const result = await FirebaseService.getAllLocations();
        console.log('📍 Load locations result:', result);
        
        if (result.success) {
            locationsData = result.data || [];
            window.locationsData = locationsData; // Update global reference
            console.log(`✅ Loaded ${locationsData.length} locations:`, locationsData);
            displayLocations(locationsData);
        } else {
            console.error('❌ Error loading locations:', result.error);
            showNotification('Failed to load locations: ' + (result.error || 'Unknown error'), 'error');
            // Show empty state
            displayLocations([]);
        }
    } catch (error) {
        console.error('❌ Exception loading locations:', error);
        showNotification('Failed to load locations: ' + error.message, 'error');
        displayLocations([]);
    }
}

function displayLocations(locations) {
    console.log('📊 Displaying locations:', locations);
    const tbody = document.getElementById('locations-table-body');
    if (!tbody) {
        console.error('❌ locations-table-body not found!');
        return;
    }
    
    if (!locations || locations.length === 0) {
        console.log('⚠️ No locations to display');
        tbody.innerHTML = `
            <tr>
                <td colspan="6" style="text-align: center; padding: 40px; color: #999;">
                    <i class="fas fa-map-marker-alt" style="font-size: 48px; margin-bottom: 16px; display: block;"></i>
                    <p>No locations found. Click "Add Location" to create your first location.</p>
                </td>
            </tr>
        `;
        return;
    }
    
    console.log(`✅ Displaying ${locations.length} locations`);
    
    tbody.innerHTML = locations.map((location, index) => {
        const createdAt = location.createdAt ? 
            new Date(location.createdAt.seconds * 1000).toLocaleDateString() : 
            'N/A';
        
        return `
            <tr>
                <td>${escapeHtml(location.name)}</td>
                <td>${escapeHtml(location.description || '-')}</td>
                <td>${location.displayOrder || 0}</td>
                <td>
                    <span class="status-badge ${location.isActive ? 'active' : 'inactive'}">
                        ${location.isActive ? 'Active' : 'Inactive'}
                    </span>
                </td>
                <td>${createdAt}</td>
                <td>
                    <div class="action-buttons">
                        <button class="btn-icon" onclick="editLocation('${location.id}')" title="Edit">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn-icon" onclick="toggleLocationStatus('${location.id}', ${!location.isActive})" title="${location.isActive ? 'Deactivate' : 'Activate'}">
                            <i class="fas fa-${location.isActive ? 'eye-slash' : 'eye'}"></i>
                        </button>
                        <button class="btn-icon delete" onclick="deleteLocation('${location.id}', '${escapeHtml(location.name)}')" title="Delete">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </td>
            </tr>
        `;
    }).join('');
}

function filterLocations(searchTerm) {
    if (!searchTerm) {
        displayLocations(locationsData);
        return;
    }
    
    const filtered = locationsData.filter(location => {
        const name = (location.name || '').toLowerCase();
        const description = (location.description || '').toLowerCase();
        const search = searchTerm.toLowerCase();
        return name.includes(search) || description.includes(search);
    });
    
    displayLocations(filtered);
}

async function toggleLocationStatus(locationId, isActive) {
    if (!confirm(`Are you sure you want to ${isActive ? 'activate' : 'deactivate'} this location?`)) {
        return;
    }
    
    try {
        const result = await FirebaseService.toggleLocationStatus(locationId, isActive);
        if (result.success) {
            showNotification(`Location ${isActive ? 'activated' : 'deactivated'} successfully`, 'success');
            loadLocations();
        } else {
            showNotification(result.error || 'Failed to update location status', 'error');
        }
    } catch (error) {
        console.error('Error toggling location status:', error);
        showNotification('Failed to update location status', 'error');
    }
}

async function deleteLocation(locationId, locationName) {
    if (!confirm(`Are you sure you want to delete "${locationName}"? This action cannot be undone.`)) {
        return;
    }
    
    try {
        const result = await FirebaseService.deleteLocation(locationId);
        if (result.success) {
            showNotification('Location deleted successfully', 'success');
            loadLocations();
        } else {
            showNotification(result.error || 'Failed to delete location', 'error');
        }
    } catch (error) {
        console.error('Error deleting location:', error);
        showNotification('Failed to delete location', 'error');
    }
}

function editLocation(locationId) {
    const location = (window.locationsData || locationsData).find(loc => loc.id === locationId);
    if (location) {
        openLocationModal(location);
    } else {
        console.error('Location not found:', locationId);
    }
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function showNotification(message, type = 'info') {
    // Simple notification - you can enhance this with a toast library
    alert(message);
}
