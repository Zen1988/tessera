(function () {
    'use strict';
    function start() {
        const root = document.getElementById('NetworkSimulation');
        if (!root || root.dataset.initialized) return;
        root.dataset.initialized = 'true';
        const payload = document.getElementById('SimulationPayload');
        let data;
        try { data = JSON.parse(payload.textContent); } catch (_) { return; }
        // Native JSON may encode numeric-looking CMDB IDs as numbers. DOM values are strings.
        function identifiers(item) {
            const normalized = Object.assign({}, item);
            ['ID', 'ApplicationID', 'Source', 'Target'].forEach(key => {
                if (normalized[key] !== undefined && normalized[key] !== null) normalized[key] = String(normalized[key]);
            });
            return normalized;
        }
        const assets = (data.Assets || []).map(identifiers);
        const form = document.getElementById('SimulationForm');
        const svg = document.getElementById('SimulationGraph');
        const viewport = document.getElementById('SimulationGraphViewport');
        const inspector = document.getElementById('SimulationInspector');
        const empty = document.getElementById('SimulationEmpty');
        const progress = document.getElementById('SimulationProgress');
        const ns = 'http://www.w3.org/2000/svg';
        let result = data.Result ? Object.assign({}, data.Result) : null;
        if (result) ['Nodes', 'Hops', 'Edges', 'DisplayNodes', 'DisplayEdges'].forEach(key => {
            if (Array.isArray(result[key])) result[key] = result[key].map(identifiers);
        });
        let scale = 1, panX = 0, panY = 0, nodes = [], selected = null, vertical = false, viewWidth = 960, viewHeight = 420;
        function element(tag, attrs, text) {
            const item = document.createElementNS(ns, tag);
            Object.keys(attrs || {}).forEach(key => item.setAttribute(key, attrs[key]));
            if (text !== undefined) item.textContent = text;
            return item;
        }
        function options(select, items, placeholder, previous) {
            select.replaceChildren(new Option(placeholder, ''));
            items.forEach(item => select.add(new Option(item.label, item.value)));
            if (items.some(item => item.value === previous)) select.value = previous;
            else if (items.length === 1) select.value = items[0].value;
        }
        function endpoint(side) {
            const key = document.getElementById(side + 'Endpoint').value;
            for (const asset of assets) {
                const found = (asset.Endpoints || []).find(item => item.Key === key);
                if (found) return {ID: asset.ID, Name: asset.Name, Class: asset.Class, Address: found.Address};
            }
            return null;
        }
        function contextNodes(side) {
            const app = document.getElementById(side + 'Application').value;
            const system = document.getElementById(side + 'System').value;
            if (!app && !system) return [];
            return assets.filter(asset => (!app || asset.ApplicationID === app) && (!system || asset.ID === system)).map(asset => ({
                ID: asset.ID, Name: asset.Name, Class: asset.Class,
                Address: (asset.Endpoints || []).map(item => item.Address).join(', ')
            }));
        }
        function transform() { viewport.setAttribute('transform', 'translate(' + panX + ' ' + panY + ') scale(' + scale + ')'); }
        function choose(id) {
            selected = nodes.find(node => node.ID === id);
            inspector.replaceChildren();
            if (!selected) return;
            const title = document.createElement('h3'); title.textContent = selected.Name; inspector.appendChild(title);
            if (selected.Restricted || selected.Placeholder) {
                const note = document.createElement('p');
                note.textContent = selected.Restricted ? 'Device details are restricted.' : 'Missing network evidence; device count and connectivity are unknown.';
                inspector.appendChild(note);
                if (selected.ApplicationName) {const app = document.createElement('p');app.textContent = 'Application: ' + selected.ApplicationName;inspector.appendChild(app);}
                return;
            }
            const list = document.createElement('dl');
            [['CMDB identifier', selected.ID], ['Class', selected.Class], ['Selected address', selected.Address || 'Not an endpoint selection'], ['Evidence', selected.Evidence || 'CMDB selection only'], ['Trace', selected.TraceStatus || 'Not evaluated']].forEach(pair => {
                const term = document.createElement('dt'), value = document.createElement('dd');
                term.textContent = pair[0]; value.textContent = pair[1]; list.append(term, value);
            });
            inspector.appendChild(list);
            const link = document.createElement('a');
            const url = new URL(form.action, window.location.href);
            url.search = ''; url.searchParams.set('Action', 'CustomerITSMConfigItemZoom'); url.searchParams.set('ConfigItemID', selected.ID);
            link.href = url.href; link.textContent = 'Open CMDB record'; inspector.appendChild(link);
            viewport.querySelectorAll('[data-node]').forEach(item => item.classList.toggle('is-selected', item.dataset.node === id));
        }
        function draw() {
            const map = new Map();
            const source = endpoint('Source'), destination = endpoint('Destination');
            if (!result) contextNodes('Source').forEach(node => map.set(node.ID, node));
            if (source) map.set(source.ID, source);
            if (result) (result.Hops || []).forEach(hop => {
                const node = (result.Nodes || []).find(item => item.ID === hop.ID);
                if (node) map.set(node.ID, node);
            });
            if (result && result.DisplayNodes) result.DisplayNodes.forEach(node => map.set(node.ID, Object.assign({}, map.get(node.ID) || {}, node)));
            if (destination) map.set(destination.ID, Object.assign({}, destination, map.get(destination.ID) || {}));
            if (!result) contextNodes('Destination').forEach(node => { if (!map.has(node.ID)) map.set(node.ID, node); });
            nodes = Array.from(map.values());
            if (result && result.DisplayEdges && source) {
                const order = [], seen = new Set();
                function walk(id) {if (seen.has(id) || !map.has(id)) return;seen.add(id);order.push(map.get(id));
                    result.DisplayEdges.filter(edge => edge.Source === id).forEach(edge => walk(edge.Target));}
                walk(source.ID);nodes.forEach(node => walk(node.ID));nodes = order;
            }
            viewport.replaceChildren();
            empty.hidden = nodes.length > 0;
            const positions = new Map();
            vertical = svg.getBoundingClientRect().width < 600;
            viewWidth = vertical ? 300 : 960;viewHeight = vertical ? Math.max(420, Math.min(720, nodes.length * 120 + 80)) : 420;
            svg.setAttribute('viewBox', '0 0 ' + viewWidth + ' ' + viewHeight);
            svg.classList.toggle('NetworkSimulation__graph--vertical', vertical);
            nodes.forEach((node, index) => positions.set(node.ID, vertical ? {x: 150, y: 80 + index * 120} : {x: 130 + index * 220, y: 210}));
            if (result) (result.DisplayEdges || result.Edges || []).forEach(edge => {
                const a = positions.get(edge.Source), b = positions.get(edge.Target);
                if (a && b) viewport.appendChild(element('path', {d: 'M' + a.x + ',' + a.y + ' L' + b.x + ',' + b.y, class: 'NetworkSimulation__edge' + (edge.Kind === 'unknown' ? ' NetworkSimulation__edge--unknown' : '')}));
            });
            nodes.forEach(node => {
                const position = positions.get(node.ID);
                const group = element('g', {transform: 'translate(' + position.x + ' ' + position.y + ')', class: 'NetworkSimulation__node' + (node.Restricted ? ' NetworkSimulation__node--restricted' : node.Placeholder ? ' NetworkSimulation__node--gap' : ''), tabindex: '0', role: 'button', 'aria-label': 'Inspect ' + node.Name, 'data-node': node.ID});
                group.appendChild(element('rect', {x: -90, y: -43, width: 180, height: 86, rx: 10}));
                group.appendChild(element('title', {}, node.Name + ' — ' + node.ID));
                group.appendChild(element('text', {x: 0, y: -10, 'text-anchor': 'middle'}, node.Name.length > 22 ? node.Name.slice(0, 20) + '…' : node.Name));
                const addressLabel = node.ApplicationName ? 'Application: ' + node.ApplicationName : node.Address || node.Class;
                group.appendChild(element('text', {x: 0, y: 12, 'text-anchor': 'middle'}, addressLabel.length > 24 ? addressLabel.slice(0, 22) + '…' : addressLabel));
                group.appendChild(element('text', {x: 0, y: 31, 'text-anchor': 'middle'}, node.Restricted ? 'Details restricted' : node.Placeholder ? 'Unknown segment' : node.TraceStatus === 'not_traced' ? 'Not traced' : node.Evidence || 'CMDB asset'));
                group.addEventListener('click', () => choose(node.ID));
                group.addEventListener('keydown', event => { if (event.key === 'Enter' || event.key === ' ') { event.preventDefault(); choose(node.ID); } });
                viewport.appendChild(group);
            });
            reset();
            if (selected && nodes.some(node => node.ID === selected.ID)) choose(selected.ID);
            else { selected = null; inspector.replaceChildren(); const note = document.createElement('p'); note.textContent = 'Select a node or a device in the path table.'; inspector.appendChild(note); }
        }
        function changed() { result = null; progress.textContent = data.Result ? 'Inputs changed. Evidence below belongs to the saved analysis until you run again.' : ''; draw(); }
        function hydrate(side, initial) {
            const app = document.getElementById(side + 'Application');
            const system = document.getElementById(side + 'System');
            const ip = document.getElementById(side + 'Endpoint');
            const filtered = assets.filter(asset => !app.value || asset.ApplicationID === app.value);
            options(system, filtered.map(asset => ({value: asset.ID, label: asset.Name + ' (' + asset.Class + ')'})), 'All permitted systems', initial ? data.Selection[side + 'System'] : system.value);
            const endpoints = filtered.filter(asset => !system.value || asset.ID === system.value).flatMap(asset => (asset.Endpoints || []).map(item => ({value: item.Key, label: item.Address + ' — ' + asset.Name})));
            options(ip, endpoints, 'Select an address', initial ? data.Selection[side + 'Endpoint'] : ip.value);
        }
        const topologyApplication = document.getElementById('SimulationTopologyApplication');
        if (topologyApplication) topologyApplication.addEventListener('change', changed);
        ['Source', 'Destination'].forEach(side => {
            const app = document.getElementById(side + 'Application');
            app.value = data.Selection[side + 'Application'] || '';
            hydrate(side, true);
            app.addEventListener('change', () => { document.getElementById(side + 'System').value = ''; document.getElementById(side + 'Endpoint').value = ''; hydrate(side, false); changed(); });
            document.getElementById(side + 'System').addEventListener('change', () => { document.getElementById(side + 'Endpoint').value = ''; hydrate(side, false); changed(); });
            document.getElementById(side + 'Endpoint').addEventListener('change', changed);
        });
        function reset() { scale = vertical ? 1 : Math.min(1, 850 / Math.max(220, nodes.length * 220)); panX = 0; panY = vertical ? 0 : 210 * (1 - scale); transform(); }
        document.getElementById('SimulationZoomIn').addEventListener('click', () => { scale = Math.min(3, scale * 1.2); transform(); });
        document.getElementById('SimulationZoomOut').addEventListener('click', () => { scale = Math.max(.06, scale / 1.2); transform(); });
        document.getElementById('SimulationReset').addEventListener('click', reset);
        let drag = null;
        svg.addEventListener('pointerdown', event => { if (event.target.closest('[data-node]')) return; drag = {x: event.clientX, y: event.clientY, px: panX, py: panY}; svg.setPointerCapture(event.pointerId); });
        svg.addEventListener('pointermove', event => { if (!drag) return; const rect = svg.getBoundingClientRect(); panX = drag.px + (event.clientX - drag.x) * viewWidth / rect.width; panY = drag.py + (event.clientY - drag.y) * viewHeight / rect.height; transform(); });
        svg.addEventListener('pointerup', () => { drag = null; }); svg.addEventListener('pointercancel', () => { drag = null; });
        root.querySelectorAll('[data-device]').forEach(button => button.addEventListener('click', () => choose(button.dataset.device)));
        const protocol = document.getElementById('SimulationProtocol'), port = document.getElementById('SimulationPort');
        function service() { const icmp = protocol.value.startsWith('icmp'); port.disabled = icmp; port.required = !icmp; if (icmp) port.value = ''; }
        protocol.addEventListener('change', () => { service(); changed(); }); port.addEventListener('input', changed); service();
        form.addEventListener('submit', () => { progress.textContent = 'TESSERA is requesting analysis. Please wait; do not resubmit.'; form.querySelector('button[type=submit]').disabled = true; });
        draw();
    }
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', start); else start();
}());
