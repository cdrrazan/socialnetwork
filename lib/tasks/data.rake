namespace :data do
  desc "Report rows that break the app's data rules (exits with status 1 if any are found)"
  task audit: :environment do
    audit = DataAudit.new
    puts audit.report
    exit 1 unless audit.clean?
  end

  desc "Recalculate comment, answer and vote counter caches"
  task reset_counters: :environment do
    updated = DataAudit.reset_counters!
    puts "Reset counters on #{updated} record(s)."
  end
end
