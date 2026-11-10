// CaptaLead — Gerenciador de Campos Dinâmicos do Formulário de Lead
class LeadFormController {
  constructor() {
    this.fieldCounter = 0;
    this.init();
  }

  init() {
    this.bindEvents();
    this.initializeCounter();
  }

  initializeCounter() {
    const existingFields = document.querySelectorAll('.field-row');
    this.fieldCounter = existingFields.length;
  }

  bindEvents() {
    // Adicionar campo genérico
    const addBtn = document.getElementById('add-field');
    if (addBtn) {
      addBtn.addEventListener('click', (e) => {
        e.preventDefault();
        this.addField('text');
      });
    }

    // Adicionar telefone
    const addPhone = document.getElementById('add-phone');
    if (addPhone) {
      addPhone.addEventListener('click', (e) => {
        e.preventDefault();
        this.addField('phone');
      });
    }

    // Adicionar email
    const addEmail = document.getElementById('add-email');
    if (addEmail) {
      addEmail.addEventListener('click', (e) => {
        e.preventDefault();
        this.addField('email');
      });
    }

    // Adicionar textarea
    const addTextarea = document.getElementById('add-textarea');
    if (addTextarea) {
      addTextarea.addEventListener('click', (e) => {
        e.preventDefault();
        this.addField('textarea');
      });
    }

    // Adicionar select
    const addSelect = document.getElementById('add-select');
    if (addSelect) {
      addSelect.addEventListener('click', (e) => {
        e.preventDefault();
        this.addField('select');
      });
    }

    // Delegação de evento para remover campos
    document.addEventListener('click', (e) => {
      if (e.target.closest('.remove-field')) {
        e.preventDefault();
        this.removeFieldElement(e.target.closest('.remove-field'));
      }
    });

    // Toggle modo JSON (edição)
    const toggleJsonBtn = document.querySelector('[data-action="lead-form#toggleJson"]');
    if (toggleJsonBtn) {
      toggleJsonBtn.addEventListener('click', (e) => {
        e.preventDefault();
        this.toggleJsonMode();
      });
    }
  }

  addField(type = 'text') {
    const template = document.getElementById('field-template');
    const container = document.getElementById('fields-container');
    
    if (!template || !container) return;

    this.fieldCounter++;
    const index = `new_${this.fieldCounter}_${Date.now()}`;
    
    // Clona o template
    const newField = template.cloneNode(true);
    newField.style.display = '';
    newField.id = `field-${index}`;
    
    // Substitui os placeholders de índice
    const html = newField.innerHTML
      .replace(/NEW_FIELD_INDEX/g, index)
      .replace(/id="field-NEW_FIELD_INDEX"/g, `id="field-${index}"`);
    
    newField.innerHTML = html;
    
    // Define valores padrão baseado no tipo
    const typeSelect = newField.querySelector('.field-type');
    const valueInput = newField.querySelector('.field-value');
    const labelInput = newField.querySelector('.field-label');
    
    if (typeSelect) typeSelect.value = type;
    
    // Placeholders por tipo
    const placeholders = {
      text: 'Valor da resposta...',
      select: 'Opção selecionada...',
      phone: '(11) 99999-0000',
      whatsapp: '(11) 99999-0000',
      email: 'exemplo@empresa.com',
      cpf: '123.456.789-00',
      cnpj: '12.345.678/0001-00',
      address: 'Rua das Flores, 123',
      textarea: 'Descreva sua necessidade...',
      password: '••••••••'
    };
    
    if (valueInput && placeholders[type]) {
      valueInput.placeholder = placeholders[type];
    }
    
    if (labelInput && !labelInput.value) {
      const labels = {
        text: 'Campo de texto',
        select: 'Campo de seleção',
        phone: 'Telefone',
        whatsapp: 'WhatsApp',
        email: 'E-mail',
        cpf: 'CPF',
        cnpj: 'CNPJ',
        address: 'Endereço',
        textarea: 'Observações',
        password: 'Senha'
      };
      labelInput.value = labels[type] || 'Novo campo';
    }

    container.insertBefore(newField, container.firstChild);
    this.scrollToNewField(newField);
  }

  removeFieldElement(button) {
    const fieldRow = button.closest('.field-row');
    if (!fieldRow) return;

    // Marca para destruição se existir campo oculto _destroy
    const destroyInput = fieldRow.querySelector('.field-destroy');
    if (destroyInput) {
      destroyInput.value = '1';
    }

    // Animação de remoção
    fieldRow.style.opacity = '0';
    fieldRow.style.transform = 'translateX(-20px)';
    fieldRow.style.transition = 'all 0.2s ease';

    setTimeout(() => {
      fieldRow.remove();
    }, 200);
  }

  // Exposta globalmente para o onclick do template
  window.removeField = (button) => {
    this.removeFieldElement(button);
  };

  toggleJsonMode() {
    const dynamic = document.getElementById('fields-dynamic');
    const json = document.getElementById('fields-json');
    const btn = document.querySelector('[data-action="lead-form#toggleJson"]');
    
    if (!dynamic || !json) return;

    if (json.style.display === 'none') {
      dynamic.style.display = 'none';
      json.style.display = 'block';
      btn.innerHTML = '<i class="bi bi-grid me-1"></i> Modo Visual';
      btn.classList.replace('btn-outline-secondary', 'btn-outline-primary');
    } else {
      dynamic.style.display = 'block';
      json.style.display = 'none';
      btn.innerHTML = '<i class="bi bi-code-slash me-1"></i> Modo JSON';
      btn.classList.replace('btn-outline-primary', 'btn-outline-secondary');
    }
  }

  scrollToNewField(element) {
    setTimeout(() => {
      element.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }, 100);
  }
}

// Inicializa quando o DOM estiver pronto
document.addEventListener('DOMContentLoaded', () => {
  if (document.querySelector('[data-controller="lead-form"]')) {
    window.leadForm = new LeadFormController();
  }
});
