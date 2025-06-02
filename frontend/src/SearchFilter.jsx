import React, { useState } from 'react';

function SearchFilter({ onSearchChange, currentSearch }) {
  const [searchInput, setSearchInput] = useState(currentSearch || '');

  const handleSubmit = (e) => {
    e.preventDefault();
    onSearchChange(searchInput);
  };

  const handleClear = () => {
    setSearchInput('');
    onSearchChange('');
  };

  return (
    <div className="row mb-4">
      <div className="col-md-8 offset-md-2">
        <div className="card">
          <div className="card-body">
            <form onSubmit={handleSubmit}>
              <div className="input-group">
                <input
                  type="text"
                  className="form-control"
                  placeholder="Search products..."
                  value={searchInput}
                  onChange={(e) => setSearchInput(e.target.value)}
                />
                <button className="btn btn-primary" type="submit">
                  Search
                </button>
                {searchInput && (
                  <button 
                    className="btn btn-outline-secondary" 
                    type="button"
                    onClick={handleClear}
                  >
                    Clear
                  </button>
                )}
              </div>
            </form>
          </div>
        </div>
      </div>
    </div>
  );
}

export default SearchFilter;