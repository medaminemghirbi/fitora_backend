require "prawn"
require "prawn/table"

# PDF's built-in fonts (WinAnsi/CP1252) cover accented French fine; every
# string here is already checked against that encoding, so the warning is
# noise, not a real limitation.
Prawn::Fonts::AFM.hide_m17n_warning = true

module Receipts
  # Builds the Premium "receipt/invoice" PDF for one membership — the
  # company's letterhead, the client and plan details, and a table of
  # every payment recorded against it with a running balance. Downloaded
  # on demand (MembershipsController#receipt), not stored anywhere.
  class MembershipPdf
    BRAND = "4F46E5".freeze

    def self.call(membership:)
      new(membership: membership).call
    end

    def initialize(membership:)
      @membership = membership
      @company = membership.company
      @client = membership.client
      @plan = membership.membership_plan
    end

    def call
      Prawn::Document.new(page_size: "A4", margin: 48) do |pdf|
        header(pdf)
        title(pdf)
        parties(pdf)
        plan_details(pdf)
        payments_table(pdf)
        totals(pdf)
        footer(pdf)
      end.render
    end

    private

    attr_reader :membership, :company, :client, :plan

    def header(pdf)
      pdf.fill_color BRAND
      pdf.text company.name, size: 20, style: :bold
      pdf.fill_color "000000"

      address_line = [ company.address, company.city, company.country ].compact_blank.join(", ")
      pdf.text address_line, size: 9, color: "555555" if address_line.present?

      contact_line = [ company.phone, company.email ].compact_blank.join(" · ")
      pdf.text contact_line, size: 9, color: "555555" if contact_line.present?

      pdf.stroke_color BRAND
      pdf.move_down 8
      pdf.stroke_horizontal_rule
      pdf.stroke_color "000000"
      pdf.move_down 12
    end

    def title(pdf)
      pdf.text "Reçu / Facture", size: 16, style: :bold
      pdf.text "N° #{membership.id.split('-').first.upcase}", size: 9, color: "555555"
      pdf.move_down 12
    end

    def parties(pdf)
      pdf.text "Client", size: 10, style: :bold
      pdf.text client.full_name, size: 10
      pdf.text client.phone, size: 10, color: "555555" if client.phone.present?
      pdf.text client.email, size: 10, color: "555555" if client.email.present?
      pdf.move_down 12
    end

    def plan_details(pdf)
      rows = [
        [ "Forfait", plan.name ],
        [ "Période", "#{membership.starts_at.to_date.strftime('%d/%m/%Y')} au #{membership.expires_at&.to_date&.strftime('%d/%m/%Y') || 'Illimitée'}" ],
        [ "Prix du forfait", format_money(plan.price, plan.currency) ],
        [ "Remise", format_money(membership.discount, plan.currency) ],
        [ "Prix final", format_money(membership.final_price, plan.currency) ],
        [ "Statut du paiement", payment_status_label ]
      ]

      pdf.table(rows, width: pdf.bounds.width) do |t|
        t.cells.borders = [ :bottom ]
        t.cells.border_color = "E2E8F0"
        t.cells.padding = [ 6, 4 ]
        t.column(0).font_style = :bold
        t.column(0).width = 150
      end
      pdf.move_down 16
    end

    def payments_table(pdf)
      pdf.text "Paiements", size: 10, style: :bold
      pdf.move_down 4

      paid_payments = membership.payments.paid.order(:paid_at)

      if paid_payments.none?
        pdf.text "Aucun paiement enregistré.", size: 9, color: "888888"
        pdf.move_down 12
        return
      end

      header_row = [ "Date", "Méthode", "Montant" ]
      rows = paid_payments.map do |payment|
        [ payment.paid_at&.strftime("%d/%m/%Y"), payment_method_label(payment.payment_method), format_money(payment.amount, payment.currency) ]
      end

      pdf.table([ header_row ] + rows, width: pdf.bounds.width) do |t|
        t.row(0).background_color = BRAND
        t.row(0).text_color = "FFFFFF"
        t.row(0).font_style = :bold
        t.cells.padding = [ 6, 4 ]
        t.cells.borders = [ :bottom ]
        t.cells.border_color = "E2E8F0"
        t.column(2).align = :right
      end
      pdf.move_down 16
    end

    def totals(pdf)
      total_paid = membership.payments.paid.sum(:amount)
      balance = [ membership.final_price.to_f - total_paid.to_f, 0 ].max

      pdf.text "Total payé : #{format_money(total_paid, plan.currency)}", size: 10, style: :bold
      pdf.text "Solde restant : #{format_money(balance, plan.currency)}", size: 10, style: :bold, color: balance.positive? ? "DC2626" : "16A34A"
    end

    def footer(pdf)
      pdf.move_down 24
      pdf.text "Généré le #{Time.current.strftime('%d/%m/%Y %H:%M')}", size: 8, color: "888888"
    end

    def payment_status_label
      { "unpaid" => "Impayé", "partial" => "Partiellement payé", "paid" => "Payé intégralement" }.fetch(membership.payment_status, membership.payment_status)
    end

    def payment_method_label(method)
      { "cash" => "Espèces", "card" => "Carte", "bank_transfer" => "Virement", "other" => "Autre" }.fetch(method, method)
    end

    def format_money(amount, currency)
      value = amount.to_f
      formatted = value == value.round ? value.round.to_s : format("%.2f", value)
      "#{formatted} #{currency}"
    end
  end
end
