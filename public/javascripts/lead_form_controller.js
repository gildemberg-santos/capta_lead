// CaptaLead — Gerenciador de Campos Dinâmicos do Formulário de Lead
(function() {
  'use strict';

  var fieldCounter = 0;
  var fieldSets = [];

  function initializeCounter() {
    var existingFields = document.querySelectorAll('.field-row');
    fieldCounter = existingFields.length;
  }

  function addField(type, label) {
    var template = document.getElementById('field-template');
    var container = document.getElementById('fields-container');

    if (!template || !container) return null;

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

    if (labelInput) {
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
      labelInput.value = label || labels[type] || 'Novo campo';
    }

    container.insertBefore(newField, container.firstChild);

    // Scroll suave para o novo campo
    setTimeout(function() {
      newField.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }, 100);

    return newField;
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

  // ---------------------------------------------------------------------------
  // Conjuntos de campos (field sets) por empresa
  // ---------------------------------------------------------------------------

  function loadFieldSets() {
    var picker = document.getElementById('field-sets-picker');
    if (!picker) return;

    try {
      fieldSets = JSON.parse(picker.getAttribute('data-field-sets') || '[]');
    } catch (e) {
      fieldSets = [];
    }

    if (!Array.isArray(fieldSets)) fieldSets = [];
  }

  function currentCompanyId() {
    var select = document.getElementById('lead_company_id');
    return select ? select.value : null;
  }

  function fieldSetsForCurrentCompany() {
    var companyId = currentCompanyId();

    return fieldSets.filter(function(fieldSet) {
      return !companyId || String(fieldSet.company_id) === String(companyId);
    });
  }

  function refreshFieldSets() {
    var select = document.getElementById('field-set-select');
    var button = document.getElementById('apply-field-set');
    if (!select) return;

    var available = fieldSetsForCurrentCompany();
    select.innerHTML = '';

    if (available.length === 0) {
      var emptyOption = document.createElement('option');
      emptyOption.value = '';
      emptyOption.textContent = 'Nenhum conjunto cadastrado para esta empresa';
      select.appendChild(emptyOption);
      select.disabled = true;
      if (button) button.disabled = true;
      return;
    }

    var placeholder = document.createElement('option');
    placeholder.value = '';
    placeholder.textContent = 'Selecione um conjunto...';
    select.appendChild(placeholder);

    available.forEach(function(fieldSet) {
      var option = document.createElement('option');
      option.value = fieldSet.id;
      option.textContent = fieldSet.name + ' (' + (fieldSet.fields || []).length + ' campos)';
      select.appendChild(option);
    });

    select.disabled = false;
    if (button) button.disabled = false;
  }

  function applyFieldSet() {
    var select = document.getElementById('field-set-select');
    var container = document.getElementById('fields-container');
    if (!select || !container || !select.value) return;

    var selected = fieldSetsForCurrentCompany().filter(function(fieldSet) {
      return String(fieldSet.id) === String(select.value);
    })[0];
    if (!selected) return;

    // Remove linhas totalmente vazias (ex.: campo inicial em branco)
    var rows = container.querySelectorAll('.field-row');
    Array.prototype.forEach.call(rows, function(row) {
      var rowLabel = row.querySelector('.field-label');
      var rowValue = row.querySelector('.field-value');
      var labelText = rowLabel ? rowLabel.value.trim() : '';
      var valueText = rowValue ? rowValue.value.trim() : '';
      if (labelText || valueText) return;

      // Remove também o wrapper criado a partir do template, se houver
      var target = row.parentElement && row.parentElement.id !== 'fields-container' ? row.parentElement : row;
      target.remove();
    });

    // Evita duplicar labels já presentes no formulário
    var existingLabels = {};
    Array.prototype.forEach.call(container.querySelectorAll('.field-label'), function(input) {
      existingLabels[input.value.trim().toLowerCase()] = true;
    });

    (selected.fields || []).forEach(function(field) {
      var label = (field.label || '').trim();
      if (!label || existingLabels[label.toLowerCase()]) return;

      var newRow = addField(field.type || 'text', label);
      if (!newRow) return;

      // addField insere no início; move para o fim para manter a ordem do conjunto
      container.appendChild(newRow);
      existingLabels[label.toLowerCase()] = true;
    });
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

    // Conjuntos de campos da empresa
    loadFieldSets();
    refreshFieldSets();

    var companySelect = document.getElementById('lead_company_id');
    if (companySelect) {
      companySelect.addEventListener('change', function() {
        refreshFieldSets();
      });
    }

    var applyFieldSetBtn = document.getElementById('apply-field-set');
    if (applyFieldSetBtn) {
      applyFieldSetBtn.addEventListener('click', function(e) {
        e.preventDefault();
        applyFieldSet();
      });
    }

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
    window.applyFieldSet = applyFieldSet;
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

})();
