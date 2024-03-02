import React, { useState, useEffect } from "react";
import { Card, Transition } from "semantic-ui-react";
import Calendar from "react-github-contribution-calendar";
import "react-calendar-heatmap/dist/styles.css";
import axios from "axios";
import "semantic-ui-css/semantic.min.css";
import MessageBox from "../Shared/MessageBox";
import "../Styles/default";

function Heatmap() {
  // useStates:
  const [records, setRecords] = useState();
  const [until, setUntil] = useState();
  const [visible, setVisible] = useState(false);

  // Transitions only work if they are flipped from false to true
  useEffect(() => {
    setVisible(true);
  }, []);

  // fetch data from server
  useEffect(() => {
    axios.get(`/history_activity.json`).then((response) => {
      setRecords(response.data.values);
      setUntil(response.data.until);
      // console.log("Heatmap", response.data.values, response.data.until);
    });
  }, []);

  // if (!records) {
  //   return <div>Loading...</div>;
  // }

  // panel color configuration
  const panelColors = [
    "#e2e0e0",
    "#6D9DC5",
    "#5F94BF",
    "#508AB9",
    "#4680AF",
    "#3d7199",
  ];

  return (
    <Transition visible={visible} animation="fade left" duration={1000}>
      <Card fluid>
        <Card.Content>
          <Card.Header>History Activity</Card.Header>
        </Card.Content>
        <Card.Content className="content-heatmap">
          {!records && (
            <MessageBox status="Loading" message={"Building Heatmap"} />
          )}
          {records && (
            <div className="no-padding no-margin">
              <Calendar
                values={records}
                until={until}
                panelColors={panelColors}
              />
            </div>
          )}
        </Card.Content>
      </Card>
    </Transition>
  );
}

export default Heatmap;
