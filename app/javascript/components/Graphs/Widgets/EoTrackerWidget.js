import React, { useState, useEffect } from "react";
import {
  Card,
  Button,
  Header,
  List,
  Icon,
  Transition,
} from "semantic-ui-react";

function EoTrackerWidget({ records }) {
  const [visible, setVisible] = useState(false);

  // Transitions only work if they are flipped from false to true
  useEffect(() => {
    setTimeout(() => {
      setVisible(true);
    }, 400);
  }, []);
  return (
    <Transition visible={visible} animation="vertical flip" duration={1000}>
      <Card color={records.uploads_that_need_eos == 0 ? "green" : "red"}>
        <Card.Content>
          <Header as="h4">EO Tracker</Header>
        </Card.Content>
        <Card.Content>
          <List animated verticalAlign="middle">
            {records.uploads_that_need_eos > 0 && (
              <List.Item>
                <List.Icon name="warning" />
                <List.Content>
                  <b>{records.uploads_that_need_eos} Footprint Uploads</b> that
                  need need Frame Centers
                </List.Content>
              </List.Item>
            )}

            {records.uploads_that_need_eos == 0 && (
              <List.Item>
                <List.Content>
                  <Icon color="green" name="checkmark" />
                  All Caught Up!
                </List.Content>
              </List.Item>
            )}
          </List>
        </Card.Content>
        <Card.Content extra>
          <Button fluid basic href="/eo_tracker">
            View Report
          </Button>
        </Card.Content>
      </Card>
    </Transition>
  );
}

export default EoTrackerWidget;
