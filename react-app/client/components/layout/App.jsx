import React from 'react';
import { CalendarComponent } from '../calendar/View.jsx';
import { InputComponent } from '../input/View.jsx';

export class App extends React.Component {
  render() {
    return (
      <div id="content">
        <h2>Timesheet</h2>
        <CalendarComponent/>
        <InputComponent/>
      </div>
    );
  }
}
