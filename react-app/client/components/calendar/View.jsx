import React from 'react';
import { Projects } from './Projects.jsx';

export class CalendarComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      data: [
        {
          id: 2,
          content: 'and another fake blab'
        },
        {
          id: 1,
          content: 'this is a fake blab'
        }
      ],
      projects: [
        '(All Projects)',
        'Alley',
        'Hack Time'
      ]
    };
  }

  render() {
    return (
      <div id="calendar-wrapper">
        <Projects data={this.state.projects}/>
        <span>Placeholder for calendar</span>
      </div>
    );
  }
}
