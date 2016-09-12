'use strict';

var Controller = require('../base/controller');
var setElementState = require('../util/dom').setElementState;

/**
 * Controller for the search bar.
 */
class SearchBarController extends Controller {
  constructor(element) {
    super(element);

    this._input = this.refs.searchBarInput;
    this._dropdown = this.refs.searchBarDropdown;
    this._dropdownItems = element.querySelectorAll('[data-ref="searchBarDropdownItem"]');

    var getActiveElementIndex = () => {
      return Array.prototype.slice.call(this._dropdownItems).
        indexOf(element.querySelector('.js-search-bar-dropdown-menu-item--active'));
    };

    var clearActiveDropdownItem = () => {
      var activeItem = element.querySelector('.js-search-bar-dropdown-menu-item--active');
      if (activeItem) {
        activeItem.classList.remove('js-search-bar-dropdown-menu-item--active');
      }
    };

    var updateActiveDropdownItem = index => {
      clearActiveDropdownItem();
      this._dropdownItems[index].classList.add('js-search-bar-dropdown-menu-item--active');
    };

    var onSelectFacet = facet => {
      this._input.value = this._input.value + facet;

      onCloseDropdown();

      setTimeout(function() {
        this._input.focus();
      }.bind(this), 0);
    };

    var setupListenerKeys = event => {
      var index = getActiveElementIndex();

      switch (event.keyCode) {
      case 13:
        // enter key
        event.preventDefault();

        var activeItem = element.querySelector('.js-search-bar-dropdown-menu-item--active');
        if (activeItem) {
          var facet = activeItem.querySelector('[data-ref="searchBarDropdownItemTitle"]').innerHTML.trim();
          onSelectFacet(facet);
        }
        break;
      case 38:
        // up key
        if (index < 0) {
          index = index + 1;
        }
        index = 
          (((index - 1) % this._dropdownItems.length) + this._dropdownItems.length) % this._dropdownItems.length;
        updateActiveDropdownItem(index);
        break;
      case 40:
        // down key
        index = (index + 1) % this._dropdownItems.length;
        updateActiveDropdownItem(index);
        break;
      default:
        break;
      }
    };

    var onCloseDropdown = () => {
      clearActiveDropdownItem();
      this.setState({open: false});
      this._input.removeEventListener('keydown', setupListenerKeys,
        true /*capture*/);
    };

    var onOpenDropdown = () => {
      this.setState({open: true});
      this._input.addEventListener('keydown', setupListenerKeys,
        true /*capture*/);
    };

    var handleClickOnItem = event => {
      var facet = event.currentTarget.querySelector('[data-ref="searchBarDropdownItemTitle"]').innerHTML.trim();
      onSelectFacet(facet);
    };

    var handleHoverOnItem = event => {
      var index = Array.prototype.slice.call(this._dropdownItems).indexOf(event.currentTarget);
      updateActiveDropdownItem(index);
    };

    var handleClickOnDropdown = event => {
      event.preventDefault();
    };
    this._dropdown.addEventListener('mousedown', handleClickOnDropdown, true);

    Object.keys(this._dropdownItems).forEach(function(key) {
      var item = this._dropdownItems[key];
      if(item && item.addEventListener) {
        item.addEventListener('mouseover', handleHoverOnItem,
          true);
        item.addEventListener('mousedown', handleClickOnItem,
          true);
      }
    }.bind(this));

    var handleFocusOutside = event => {
      if (!element.contains(event.target) || !element.contains(event.relatedTarget)) {
        this.setState({open: false});
      }
      onCloseDropdown();
    };
    this._input.addEventListener('focusout', handleFocusOutside,
      true /*capture*/);

    var handleFocusOnInput = () => {
      if (this._input.value.trim().length > 0) {
        onCloseDropdown();
      } else {
        onOpenDropdown();
      }
    };

    this._input.addEventListener('input', handleFocusOnInput,
      true /*capture*/);
    this._input.addEventListener('focusin', handleFocusOnInput,
      true /*capture*/);
  }

  update(state) {
    setElementState(this._dropdown, {open: state.open});
  }
}

module.exports = SearchBarController;
