# ProtonVPN Release: {{ release.versionString }} ({%- include "timestamp" -%})
@Metadata {
    @TechnologyRoot
}
{% if release.body %}
## Release Notes

{{ release.body }}
{% endif %}
## Changes
@TabNavigator {
{% for category, changes in release.changes %}
    @Tab("{{ category }}") {
        | Commit | Summary |
        |--------|---------|
        {% for change in changes %}| `{{ change.commitHash|prefix:oidStringLength }}` | {% if change.scope %}{{ change.scope }}: {% endif %}{{ change.summary }} |
        {% endfor %}
    }
{% endfor %}
## Topics
{% if checklist_filenames %}
### Checklists
{% for filename in checklistFilenames %}
- <article:{{ filename }}>
{% endfor %}
{% endif %}
}
