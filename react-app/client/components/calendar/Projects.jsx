import React from 'react';
import { Option } from './Option.jsx';

export class Projects extends React.Component {
  render() {
    var projects = this.props.data.map(project => {
      return (
        <Option value={ project } />
      );
    });

    return (
      <div id="filter-wrapper">
        <fieldset id="filter-wrapper">
          <legend>Filter Time Entries</legend>
          <form>
            <select id="filter_project" name="filter[project]">
              { projects }
            </select>
          </form>
        </fieldset>
      </div>
    );
  }
}
