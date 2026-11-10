# frozen_string_literal: true

module Qualification
  class Metrics
    def self.call(rows)
      tp = rows.count { |r| r[:predicted] && r[:actual] }
      fp = rows.count { |r| r[:predicted] && !r[:actual] }
      fn = rows.count { |r| !r[:predicted] && r[:actual] }
      tn = rows.count { |r| !r[:predicted] && !r[:actual] }

      {
        matriz: { vp: tp, fp:, fn:, vn: tn },
        acuracia: ratio(tp + tn, rows.size),
        precisao: ratio(tp, tp + fp),
        recall: ratio(tp, tp + fn),
        brier: rows.empty? ? nil : (rows.sum { |r| (r[:score] - (r[:actual] ? 1 : 0))**2 } / rows.size).round(3),
        calibracao: calibration(rows)
      }
    end

    def self.ratio(num, den)
      den.zero? ? nil : (num.to_f / den).round(3)
    end

    # Agrupa as notas em faixas de 0,2 e compara a nota média com a conversão real
    def self.calibration(rows)
      rows.group_by { |r| [(r[:score] * 5).floor, 4].min }.sort.map do |bucket, items|
        {
          faixa: format("%.1f–%.1f", bucket / 5.0, (bucket + 1) / 5.0),
          leads: items.size,
          nota_media: (items.sum { |r| r[:score] } / items.size).round(2),
          conversao_real: ratio(items.count { |r| r[:actual] }, items.size)
        }
      end
    end
  end
end
