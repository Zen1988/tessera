// --
// TESSERA customer asset free-text column filters.
// --
Core.ZTSM = Core.ZTSM || {};
Core.ZTSM.Customer = Core.ZTSM.Customer || {};

(function (TargetNS) {
    'use strict';

    TargetNS.Init = function () {
        $('.ZTSMAssetTextFilter').off('.ZTSMAssetFilter').on('keydown.ZTSMAssetFilter', function (Event) {
            var URL, Name, Value, Pattern, Separator;

            if (Event.key !== 'Enter') {
                return;
            }

            Event.preventDefault();
            Name = $(this).attr('name');
            Value = $(this).val() || '';
            URL = window.location.href;
            URL = URL.replace(/([?;])Subaction=[^;#]*/g, '$1');
            Pattern = new RegExp('([?;])' + Name + '=[^;#]*');
            if (URL.match(Pattern)) {
                URL = URL.replace(Pattern, '$1' + Name + '=' + encodeURIComponent(Value));
            }
            else {
                Separator = URL.indexOf('?') === -1 ? '?' : ';';
                URL += Separator + Name + '=' + encodeURIComponent(Value);
            }
            window.location.href = URL;
        });
    };
}(Core.ZTSM.Customer.AssetFilters = Core.ZTSM.Customer.AssetFilters || {}));

Core.Init.RegisterNamespace(Core.ZTSM.Customer.AssetFilters, 'APP_MODULE');
