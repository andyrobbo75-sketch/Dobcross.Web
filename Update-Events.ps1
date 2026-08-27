$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$eventsFile = Join-Path $projectRoot "Pages\upcoming-events\Index.cshtml"
$eventDetailFile = Join-Path $projectRoot "Pages\event\Index.cshtml"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Dobcross Silver Band - Events Update" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# Create backup directory
# ------------------------------------------------------------

$backupRoot = Join-Path $projectRoot "Backups"
$backupDir = Join-Path $backupRoot ("Events-" + (Get-Date -Format "yyyyMMdd-HHmmss"))

New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

Write-Host "Creating backups..." -ForegroundColor Yellow

if (Test-Path $eventsFile) {
    Copy-Item $eventsFile (Join-Path $backupDir "UpcomingEvents.Index.cshtml") -Force
}

if (Test-Path $eventDetailFile) {
    Copy-Item $eventDetailFile (Join-Path $backupDir "Event.Index.cshtml") -Force
}

Write-Host "Backup created: $backupDir" -ForegroundColor Green
Write-Host ""

# ------------------------------------------------------------
# Ensure event detail directory exists
# ------------------------------------------------------------

$eventDirectory = Split-Path -Parent $eventDetailFile

New-Item -ItemType Directory -Path $eventDirectory -Force | Out-Null

# ------------------------------------------------------------
# Upcoming Events page
# ------------------------------------------------------------

$eventsPage = @'
@page "/events"

@using OrchardCore.ContentManagement
@using OrchardCore.ContentManagement.Records
@using YesSql

@inject ISession Session

@{
    ViewData["Title"] = "Events";

    var events = await Session
        .Query<ContentItem, ContentItemIndex>()
        .Where(x => x.ContentType == "Event" && x.Published)
        .ListAsync();
}

<main>

    <section class="page-hero">
        <div class="container">
            <p class="eyebrow">What's On</p>

            <h1>Upcoming Events</h1>

            <p class="page-hero__intro">
                Find out where you can hear Dobcross Silver Band.
            </p>
        </div>
    </section>

    <section class="content-section">
        <div class="container">

            <p class="eyebrow">Band Events</p>

            @if (events.Any())
            {
                <div class="event-list">

                    @foreach (var item in events)
                    {
                        var eventDateText = item.Content?.Event?.Event?.EventDateTime?.ToString();

                        DateTime parsedDate = DateTime.MinValue;
                        bool hasDate = false;

                        if (!string.IsNullOrWhiteSpace(eventDateText))
                        {
                            hasDate = DateTime.TryParse(
                                eventDateText,
                                null,
                                System.Globalization.DateTimeStyles.RoundtripKind,
                                out parsedDate
                            );
                        }

                        <article class="event-card">

                            <h2>@item.DisplayText</h2>

                            @if (hasDate)
                            {
                                <p class="event-card__date">
                                    @parsedDate.ToLocalTime().ToString("dddd d MMMM yyyy 'at' h:mm tt")
                                </p>
                            }

                            <a class="button button--primary"
                               href="/event/@item.ContentItemId">
                                View Event
                            </a>

                        </article>
                    }

                </div>
            }
            else
            {
                <p>There are currently no upcoming events.</p>
            }

        </div>
    </section>

    <section class="content-section">
        <div class="container content-section__inner">

            <div class="content-section__heading">
                <p class="eyebrow">Your Event</p>
            </div>

            <div class="content-section__body">
                <p>
                    Interested in booking Dobcross Silver Band?
                    Get in touch with the band to discuss availability
                    and requirements.
                </p>

                <a class="button button--primary" href="/contact">
                    Contact the Band
                </a>
            </div>

        </div>
    </section>

    <section class="page-cta">
        <div class="container page-cta__inner">

            <div>
                <p class="eyebrow">Dobcross Silver Band</p>
                <h2>Keep exploring.</h2>
            </div>

            <div>
                <a class="button button--primary" href="/">
                    Return Home
                </a>
            </div>

        </div>
    </section>

</main>
'@

Set-Content -Path $eventsFile -Value $eventsPage -Encoding UTF8

Write-Host "Updated:" -ForegroundColor Green
Write-Host "  Pages\upcoming-events\Index.cshtml"

# ------------------------------------------------------------
# Event detail page
# ------------------------------------------------------------

$eventDetailPage = @'
@page "/event/{id}"

@using OrchardCore

@inject IOrchardHelper Orchard

@{
    ViewData["Title"] = "Event";

    var eventItem = await Orchard.GetContentItemByIdAsync(Id);
}

<main>

    @if (eventItem == null)
    {
        <section class="page-hero">
            <div class="container">

                <p class="eyebrow">Dobcross Silver Band</p>

                <h1>Event not found</h1>

                <p class="page-hero__intro">
                    The requested event could not be found.
                </p>

            </div>
        </section>

        <section class="content-section">
            <div class="container">

                <a class="text-link" href="/events">
                    ← Back to Events
                </a>

            </div>
        </section>
    }
    else
    {
        var eventDateText = eventItem.Content?.Event?.Event?.EventDateTime?.ToString();

        DateTime parsedDate = DateTime.MinValue;
        bool hasDate = false;

        if (!string.IsNullOrWhiteSpace(eventDateText))
        {
            hasDate = DateTime.TryParse(
                eventDateText,
                null,
                System.Globalization.DateTimeStyles.RoundtripKind,
                out parsedDate
            );
        }

        <article class="event-article">

            <header class="page-hero">
                <div class="container">

                    <p class="eyebrow">
                        Dobcross Silver Band
                    </p>

                    <h1>
                        @eventItem.DisplayText
                    </h1>

                    @if (hasDate)
                    {
                        <p class="page-hero__intro">
                            @parsedDate.ToLocalTime().ToString("dddd d MMMM yyyy 'at' h:mm tt")
                        </p>
                    }

                </div>
            </header>

            <section class="content-section">
                <div class="container">

                    @if (eventItem.Content?.MarkdownBodyPart?.Markdown != null)
                    {
                        <div class="event-article__body">

                            @await Orchard.MarkdownToHtmlAsync(
                                (string)eventItem.Content.MarkdownBodyPart.Markdown
                            )

                        </div>
                    }

                    <div class="event-article__back">

                        <a class="text-link" href="/events">
                            ← Back to Events
                        </a>

                    </div>

                </div>
            </section>

        </article>
    }

</main>

@functions
{
    [FromRoute]
    public string Id { get; set; }
}
'@

Set-Content -Path $eventDetailFile -Value $eventDetailPage -Encoding UTF8

Write-Host "Updated:" -ForegroundColor Green
Write-Host "  Pages\event\Index.cshtml"
Write-Host ""

# ------------------------------------------------------------
# Build
# ------------------------------------------------------------

Write-Host "Running dotnet build..." -ForegroundColor Yellow
Write-Host ""

Push-Location $projectRoot

try {
    dotnet build

    if ($LASTEXITCODE -ne 0) {
        throw "dotnet build failed."
    }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host " EVENTS UPDATE COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Event list:   /events"
Write-Host "Event detail: /event/{content-item-id}"
Write-Host ""
Write-Host "Backup:"
Write-Host "  $backupDir"
Write-Host ""