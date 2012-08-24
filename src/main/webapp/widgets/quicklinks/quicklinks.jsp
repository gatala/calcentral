<div class="cc-container-widget quicklinks_widget" id="cc-widget-quicklinks">
	<div class="cc-widget-title">
		<h2>Quicklinks</h2>
	</div>
	<!-- MAIN VIEW -->
    <!-- MAIN PANEL: List of links and categories. -->
    <div class="quicklinks_link_list">
        <div id="quicklinks_accordion">Loading...<!-- filled by trimpath, HACK: don't remove 'Loading...', it is here to make IE8 think that the outer widget div is not empty --></div>

        <script id="quicklinks_accordion_template" type="text/x-handlebars-template" style="display:none;">
        {{#each_with_index sections}}
            {{#if activeSection}}
                <div class="quicklinks_accordion_pane quicklinks_accordion_open" data-sectionid="{{this.index}}">
            {{else}}
                <div class="quicklinks_accordion_pane" data-sectionid="{{this.index}}">
            {{/if}}
            <div class="quicklinks_section_label">{{label}}</div>
            <div class="quicklinks_accordion_content{{#if isEditable}} quicklinks_section{{/if}}">
                <ul>
                {{#each_with_index links}}
                    <li class="link featuredcontent_content featuredcontent_content_medium">
                        <a href="{{url}}"
                            id="quicklinks_{{id}}"
                            target="_blank"
                            class="cc-widget-links"
                            data-gatrack="true">{{name}}</a>
                        {{#if section.isEditable}}
                            <div class="quicklinks_edit_buttons">
                                <div class="quicklinks_icon_button quicklinks_delete_icon quicklinks-delete-mylink" data-eltindex="{{this.index}}"><span class="cc-aural-text">Delete Link: {{name}}</div>
                                <div class="quicklinks_icon_button quicklinks_edit_icon quicklinks-edit-mylink" data-eltindex="{{this.index}}"><span class="cc-aural-text">Edit Link: ${name}}</div>
                            </div>
                        {{/if}}
                    </li>
                {{/each_with_index}}
                {{#unless links}}
                    <div class="quicklinks_no_links_message">There are no links in this section yet.</div>
                {{/unless}}
                </ul>
            </div>
            </div>
        {{/each_with_index}}
        </script>


        <!-- ADD/EDIT LINK PANEL: Allows user to add a new link or edit an existing link. -->
        <div class="quicklinks_addedit_link_panel">
            <form id="quicklinks-form" class="quicklinks-link-form cc-form-field-wrapper" action="" method="post">
                <h2 class="quicklinks_addedit_link_panel_title cc-addlink-header">Add Link</h2>
                <div class="quicklinks-link-form-element">
                        <label class="elm-label" for="quicklinks-link-title">Link Title:</label>
                        <input type="text" id="quicklinks-link-title" class="quicklinks-save-link-keydown required" name="quicklinks-link-title" aria-required="true" />
                </div>
                <div class="quicklinks-link-form-element">
                        <label class="elm-label" for="quicklinks-link-url">Link URL:</label>
                        <input type="text" id="quicklinks-link-url" name="quicklinks-link-url" aria-required="true" class="appendhttp url required quicklinks-save-link-keydown"/>
                </div>
            </form>

            <div class="quicklinks-button-list">
                <button id="quicklinks-cancel-button" class="cc-link-button cc-bold">Cancel</button>
                <button id="quicklinks-addlink-button" class="cc-button cc-overlay-button quicklinks-save-link-click"><span class="cc-button-inner cc-button-link-2-state-inner">Add Link</span></button>
                <button id="quicklinks-savelink-button" class="cc-button cc-overlay-button quicklinks-save-link-click"><span class="cc-button-inner cc-button-link-2-state-inner">Save</span></button>
            </div>
        </div>
    </div>

    <div class="cc-widget-footer">
        <button class="cc-button cc-overlay-button fl-force-right" id="quicklinks-add-link-mode">Add Link</button>
    </div>
</div>