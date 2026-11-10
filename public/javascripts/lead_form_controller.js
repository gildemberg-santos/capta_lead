// CaptaLead — Gerenciador de Campos Dinâmicos do Formulário de Lead
(function() {
  'use strict';

  var fieldCounter = 0;

  function initializeCounter() {
    var existingFields = document.querySelectorAll('.field-row');
    fieldCounter = existingFields.length;
  }

  function addField(type) {
    var template = document.getElementById('field-template');
    var container = document.getElementById('fields-container');

    if (!template || !container) return;

    fieldCounter++;
    var index = 'new_' + fieldCounter + '_' + Date.now();

    // Clona o template
    var newField = template.cloneNode(true);
    newField.style.display = '';
    newField.id = 'field-' + index;

    // Obtém o HTML e substitui placeholders
    var html = newField.innerHTML
      .replace(/NEW_FIELD_INDEX/g, index)
      .replace(/id="field-NEW_FIELD_INDEX"/g, 'id="field-' + index + '"');

    newField.innerHTML = html;

    // Configura valores padrão baseado no tipo
    var typeSelect = newField.querySelector('.field-type');
    var valueInput = newField.querySelector('.field-value');
    var labelInput = newField.querySelector('.field-label');

    if (typeSelect) typeSelect.value = type || 'text';

    var placeholders = {
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
      var labels = {
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

    // Scroll suave para o novo campo
    setTimeout(function() {
      newField.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }, 100);
  }

  function removeField(button) {
    var fieldRow = button.closest('.field-row');
    if (!fieldRow) return;

    // Marca para destruição
    var destroyInput = fieldRow.querySelector('.field-destroy');
    if (destroyInput) {
      destroyInput.value = '1';
    }

    // Animação de remoção
    fieldRow.style.opacity = '0';
    fieldRow.style.transform = 'translateX(-20px)';
    fieldRow.style.transition = 'all 0.2s ease';

    setTimeout(function() {
      fieldRow.remove();
    }, 200);
  }

  function toggleJsonMode() {
    var dynamic = document.getElementById('fields-dynamic');
    var json = document.getElementById('fields-json');
    var btn = document.querySelector('[data-action="lead-form#toggleJson"]');

    if (!dynamic || !json) return;

    if (json.style.display === 'none') {
      dynamic.style.display = 'none';
      json.style.display = 'block';
      if (btn) {
        btn.innerHTML = '<i class="bi bi-grid me-1"></i> Modo Visual';
        btn.classList.replace('btn-outline-secondary', 'btn-outline-primary');
      }
    } else {
      dynamic.style.display = 'block';
      json.style.display = 'none';
      if (btn) {
        btn.innerHTML = '<i class="bi bi-code-slash me-1"></i> Modo JSON';
        btn.classList.replace('btn-outline-primary', 'btn-outline-secondary');
      }
    }
  }

  // Inicialização quando o DOM estiver pronto
  function init() {
    initializeCounter();

    // Botão Adicionar Campo
    var addBtn = document.getElementById('add-field');
    if (addBtn) {
      addBtn.addEventListener('click', function(e) {
        e.preventDefault();
        addField('text');
      });
    }

    // Botão Telefone
    var addPhone = document.getElementById('add-phone');
    if (addPhone) {
      addPhone.addEventListener('click', function(e) {
        e.preventDefault();
        addField('phone');
      });
    }

    // Botão Email
    var addEmail = document.getElementById('add-email');
    if (addEmail) {
      addEmail.addEventListener('click', function(e) {
        e.preventDefault();
        addField('email');
      });
    }

    // Botão Texto Longo
    var addTextarea = document.getElementById('add-textarea');
    if (addTextarea) {
      addTextarea.addEventListener('click', function(e) {
        e.preventDefault();
        addField('textarea');
      });
    }

    // Botão Seleção
    var addSelect = document.getElementById('add-select');
    if (addSelect) {
      addSelect.addEventListener('click', function(e) {
        e.preventDefault();
        addField('select');
      });
    }

    // Delegação para remover campos
    document.addEventListener('click', function(e) {
      var removeBtn = e.target.closest('.remove-field');
      if (removeBtn) {
        e.preventDefault();
        removeField(removeBtn);
      }
    });

    // Toggle modo JSON
    var toggleJsonBtn = document.querySelector('[data-action="lead-form#toggleJson"]');
    if (toggleJsonBtn) {
      toggleJsonBtn.addEventListener('click', function(e) {
        e.preventDefault();
        toggleJsonMode();
      });
    }

    // Expor funções globalmente para onclick inline
    window.addField = addField;
    window.removeField = removeField;
    window.toggleJsonMode = toggleJsonMode;
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

})();
