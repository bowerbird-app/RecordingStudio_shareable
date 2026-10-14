# Recording Studio Shareable

Opt-in sharing for Recording Studio recordables. A host chooses which types can be shared. Shareable resolves one absolute public URL, builds social destination links, and can render social preview tags.

Publishable decides whether a recordable is public. Shareable only distributes an eligible URL. It does not grant access, and it does not duplicate publication rules.

This phase has no share button, menu, or Stimulus controller. FlatPack is adding a share button. `FlatPack::TextInput` and `FlatPack::TextArea` already support `quick_copy: true`. FlatPack has no `navigator.share` support yet.

## Install

```ruby
gem "recording_studio", "~> 4.2"
gem "recording_studio_shareable"
```

```bash
bundle install
bin/rails generate recording_studio_shareable:install
```

The gem has no migrations and no tables.

## Activation

Loading the gem registers `:shareable` and enables it on nothing. Opt in per recordable:

```ruby
class Page < ApplicationRecord
  recording_studio_recordable label: "Page", root: false, allowed_parent_types: ["Workspace"]

  include RecordingStudio::Capabilities::Shareable.to(
    public_url: ->(page) { "/pages/#{page.id}" }
  )
end
```

`.to` wraps `RecordingStudio::Capabilities.include_for`. Do not call `enable_capability` yourself.

## URL resolution

`RecordingStudioShareable::SharePayload.for(recordable_or_recording)` returns the share decision.

1. The recordable type must have Shareable enabled. Otherwise the payload is unavailable.
2. If Publishable is enabled for that type, the URL is `published_url` and nothing else. Drafts, scheduled records, and unpublished records return nil from Publishable, and Shareable does not fall back to another URL.
3. Otherwise Shareable calls the host `public_url` callable from `.to`, from `SharePayload.for(..., public_url:)`, or from configuration.
4. Relative paths (starting with `/`) are prefixed with `public_base_url`. Absolute `http` and `https` URLs are left as they are.
5. Blank values, non-http(s) values, and URLs whose path or query contains `active_storage`, `publishable/preview`, or `recording_studio` are rejected. Preview and admin routes are never share links.

```ruby
RecordingStudioShareable.configure do |config|
  config.public_base_url = "https://press.example"
  config.destinations = %i[copy native linkedin x facebook email]
  config.public_url = ->(recordable) { recordable.try(:public_path) }
  config.title = ->(recordable) { recordable.try(:title) }
  config.description = ->(recordable) { recordable.try(:description) }
  config.image = ->(_recordable) { "https://cdn.example/card.png" }
end
```

`public_base_url` is also read from `config/recording_studio_shareable.yml` or `Rails.application.config.x.recording_studio_shareable`.

## Title, description, and image

Title uses the first present value: an override, Publishable `social_title`, Publishable `seo_title`, `title`, `name`, then the recordable type label.

Description uses an override, `social_description`, `seo_description`, then `description`. A missing description is fine.

Image is a host-supplied absolute `https` URL only. Relative paths, `http` URLs, and Active Storage URLs are dropped. Publishable social images are not read, because those resolve through Attachable preview paths.

Pass a recording when you want Publishable text fallbacks. `current_publishable` is read from the recording, or from the recordable when it responds to that method.

## Destinations

The default list is `copy`, `native`, `linkedin`, `x`, `facebook`, and `email`. Narrow it in configuration, in `.to(destinations:)`, or as a `SharePayload` override.

Social links are normal share endpoints, with query values encoded by `URI.encode_www_form`:

- LinkedIn: `https://www.linkedin.com/sharing/share-offsite/?url=`
- X: `https://twitter.com/intent/tweet?url=&text=`
- Facebook: `https://www.facebook.com/sharer/sharer.php?u=`
- Email: `mailto:?subject=&body=`

`copy` and `native` are destination names only. They do not have URLs. Native device sharing waits on the later UI.

`payload.destination_urls` is empty when the payload is unavailable.

## Metadata

In a layout:

```erb
<%= shareable_head_tags(recording) %>
```

When Publishable is enabled for that recordable, the helper calls `publishable_head_tags` if the view has it, and otherwise renders nothing. That avoids a second set of canonical and Open Graph tags. When Publishable is not enabled, the helper emits canonical, `og:title`, `og:description`, `og:url`, `og:image`, and the matching `twitter:*` tags from the payload. Missing description or image omits those tags. An unavailable payload renders nothing.

## Security

Shareable distributes a URL. It does not call `RecordingStudioAccessible.authorized?`, and it does not make a draft reachable. If Publishable is enabled and `published_url` is blank or unsafe, sharing stays off even if the host also supplied a direct URL.

## Share UI

The gem renders the sheet with FlatPack primitives so it can move to FlatPack's share button later.

- `RecordingStudioShareable::ShareButton::Component` opens the modal.
- `RecordingStudioShareable::ShareModal::Component` shows the preview, copy field, device share, and destination icons.
- `RecordingStudioShareable::CopyLink::Component` is a read-only `FlatPack::TextInput` with `quick_copy: true`. The copied toast comes from FlatPack.
- `RecordingStudioShareable::ShareLinks::Component` builds LinkedIn, X, Facebook, and email buttons.
- `recording-studio-shareable--share` reveals the device share button only when `navigator.share` exists.

The dummy app opts `Page` into Shareable with a host `public_url` and leaves Publishable off. Sign in and open `/press` for the public page. `shareable_head_tags` render in that page's head. `Folder` stays unshared.

## Not built yet

FlatPack does not ship `navigator.share` itself. This gem's Stimulus controller covers that until a FlatPack share button replaces `ShareButton`.

## Dummy app pins

The dummy app pins these GitHub tags:

| Gem | Tag |
| --- | --- |
| RecordingStudio | dummy GitHub tag `v4.5.0` |
| Accessible | dummy GitHub tag `v0.15.0` |
| Root Switchable | dummy GitHub tag `v0.9.0` |
| FlatPack | dummy GitHub tag `v0.1.196` |

Publishable is not a dependency of this gem. The dummy app does not bundle it yet.

Sign in to the dummy app with `admin@admin.com` / `Password`.
