import React, {useState, useCallback} from 'react'
import {useCombobox} from 'downshift'
import classNames from 'classnames'
import debounce from 'debounce-promise'

function selectInputText(e) {
  e.target.select()
}

function ChevronDown() {
  return (
    <svg className="text-indigo-500 h-4 w-4" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="6 9 12 15 18 9"></polyline>
    </svg>
  )
}

function Spinner() {
  return (
    <svg className="animate-spin h-4 w-4 text-indigo-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
    </svg>
  )
}

export default function SearchSelect(props) {
  const [items, setItems] = useState([])
  const [loading, setLoading] = useState(false)
  const [initialLoadComplete, setInitialLoadComplete] = useState(false)

  function fetchOptions({inputValue, isOpen}) {
    setLoading(isOpen)

    return props.fetchOptions(inputValue).then((loadedItems) => {
      setLoading(false)
      setItems(loadedItems)
    })
  }

  const debouncedFetchOptions = useCallback(debounce(fetchOptions, 200), [])

  const {
    isOpen,
    inputValue,
    getToggleButtonProps,
    getLabelProps,
    getMenuProps,
    getInputProps,
    getComboboxProps,
    highlightedIndex,
    getItemProps,
    selectItem,
    closeMenu,
    setInputValue
  } = useCombobox({
    items: items,
    onInputValueChange: (changes) => {
      debouncedFetchOptions(changes)
      props.onInput(changes.inputValue)
    },
    initialSelectedItem: props.initialSelectedItem,
    onIsOpenChange: ({inputValue}) => {
      if (!initialLoadComplete) {
        fetchOptions({inputValue: inputValue, isOpen: true}).then(() => {
          setInitialLoadComplete(true)
        })
      }
    }
  })

  function keydown(e) {
    if (e.ctrlKey || e.metaKey || e.shiftKey || e.altKey || e.isComposing || e.keyCode === 229) return

    if (e.key == 'Enter' && isOpen && highlightedIndex === -1) {
      closeMenu()
      e.preventDefault()
    }
  }

  return (
    <div className="mt-1 relative">
      <div className="relative rounded-md shadow-sm" {...getToggleButtonProps()} {...getComboboxProps()}>
        <input {...getInputProps({onKeyDown: keydown})} onFocus={selectInputText} placeholder="Enter a filter value" type="text" className={classNames('focus:ring-indigo-500 focus:border-indigo-500 block w-full pr-10 sm:text-sm border-gray-300 rounded-md', {'cursor-pointer': inputValue === '' && !isOpen})}  />
        <div className="absolute inset-y-0 right-0 flex items-center pr-2 pointer-events-none">
          { !loading && <ChevronDown /> }
          { loading && <Spinner /> }
        </div>
      </div>
      <div {...getMenuProps()}>
        { isOpen &&
        <ul className="absolute z-10 mt-1 w-full bg-white shadow-lg max-h-60 rounded-md py-1 text-base ring-1 ring-black ring-opacity-5 overflow-auto focus:outline-none sm:text-sm">
          { !loading && items.length == 0 &&
          <li className="cursor-default select-none relative py-2 pl-3 pr-9">No results found</li>
          }
          { loading && items.length == 0 &&
          <li className="cursor-default select-none relative py-2 pl-3 pr-9">Loading options...</li>
          }

          {
            items.map((item, index) => (
              <li className={classNames("cursor-pointer select-none relative py-2 pl-3 pr-9", {'text-white bg-indigo-600': highlightedIndex === index, 'text-gray-900': highlightedIndex !== index})}
                key={`${item}${index}`}
                {...getItemProps({ item, index })}
              >
                {item}
              </li>
            ))
          }
        </ul>
        }
      </div>
    </div>
  )
}