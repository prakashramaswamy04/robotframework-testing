// Interaction behavior for the local Robot Framework mock portal.
const loginView = document.querySelector('#login-view');
const appView = document.querySelector('#app-view');
const menuButton = document.querySelector('#menu-button');
const menuPanel = document.querySelector('#menu-panel');
const quarterStatus = document.querySelector('#quarter-status');
let selectedQuarter = '';

function showView(name) {
  document.querySelectorAll('.content').forEach((view) => { view.hidden = true; });
  document.querySelector(`#${name}-view`).hidden = false;
  menuPanel.hidden = true;
  menuButton.setAttribute('aria-expanded', 'false');
}

function openReport(name) {
  const descriptions = {
    'Annual Well Visit': 'Annual preventive-visit performance by practice.',
    'ER Visits By Practice': 'Emergency-room visit utilization by practice.',
    'IP Admissions By Practice': 'Inpatient admissions by practice.',
  };
  document.querySelector('#report-title').textContent = name;
  document.querySelector('#report-description').textContent = descriptions[name];
  document.querySelector('#report-quarter').textContent = selectedQuarter || 'Not selected';
  document.querySelector('#report-breadcrumb').textContent = `Reports / ${name}`;
  showView('report');
}

document.querySelector('#login-form').addEventListener('submit', (event) => {
  event.preventDefault();
  loginView.hidden = true;
  appView.hidden = false;
});

menuButton.addEventListener('click', () => {
  menuPanel.hidden = !menuPanel.hidden;
  menuButton.setAttribute('aria-expanded', String(!menuPanel.hidden));
});

document.querySelectorAll('[role="option"]').forEach((option) => {
  option.addEventListener('click', () => {
    selectedQuarter = option.textContent.trim();
    document.querySelectorAll('[role="option"]').forEach((item) => item.setAttribute('aria-selected', 'false'));
    option.setAttribute('aria-selected', 'true');
    quarterStatus.textContent = `Selected quarter: ${selectedQuarter}`;
  });
});

document.querySelectorAll('[data-view]').forEach((link) => link.addEventListener('click', (event) => {
  event.preventDefault();
  showView(link.dataset.view);
}));
document.querySelectorAll('[data-report]').forEach((link) => link.addEventListener('click', (event) => {
  event.preventDefault();
  openReport(link.dataset.report);
}));
document.querySelector('#logout-link').addEventListener('click', (event) => {
  event.preventDefault();
  appView.hidden = true;
  loginView.hidden = false;
  document.querySelector('#login-form').reset();
  showView('home');
});
