import React, { useState, useEffect } from "react";
import {
  Card,
  Button,
  Header,
  List,
  Icon,
  Transition,
} from "semantic-ui-react";

function EasementsWithMultipleCoveragesWidget({ records }) {
  const [visible, setVisible] = useState(false);

  // Transitions only work if they are flipped from false to true
  useEffect(() => {
    setTimeout(() => {
      setVisible(true);
    }, 200)
  }, []);

  return (
    <Transition visible={visible} animation="vertical flip" duration={1000}>
      <Card
        color={
          records.records_with_coverage === 0 &&
          records.rejected_with_coverage == 0
            ? "green"
            : "red"
        }
      >
        <Card.Content>
          <Header as="h4">Easements With Multiple Coverages</Header>
        </Card.Content>
        <Card.Content>
          <List animated verticalAlign="middle">
            {records.records_with_coverage > 0 && (
              <List.Item>
                <List.Icon name="copy outline" />
                <List.Content>
                  <b>{records.records_with_coverage} Tiles</b> that have
                  overlapping footprints from another flight date
                </List.Content>
              </List.Item>
            )}
            {records.rejected_with_coverage > 0 && (
              <List.Item>
                <List.Content>
                  <Icon color="red" name="remove" />
                  <b>{records.rejected_with_coverage} Rejected Tiles</b> that
                  have coverage
                </List.Content>
              </List.Item>
            )}

            {records.records_with_coverage === 0 &&
              records.rejected_with_coverage == 0 && (
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
          <Button fluid basic href="/easements_with_multiple_coverages">
            View Report
          </Button>
        </Card.Content>
      </Card>
    </Transition>
  );
}

export default EasementsWithMultipleCoveragesWidget;
