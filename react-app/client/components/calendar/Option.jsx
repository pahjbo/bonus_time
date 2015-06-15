import React from 'react';

export class Option extends React.Component {
  render() {
    return (
      <option value={ this.props.value }>{ this.props.value }</option>
    );
  }
}
