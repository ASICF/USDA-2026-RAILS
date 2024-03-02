import React, { useState, useEffect } from "react";
import { Card, Grid, Statistic, Transition } from "semantic-ui-react";
function SlStatistics({
  states,
  counties,
  tile_count,
  tile_flown,
  flown,
  tile_shipped,
  shipped,
}) {
  const [visible, setVisible] = useState(false);

  // Transitions only work if they are flipped from false to true
  useEffect(() => {
    setVisible(true);
  }, []);

  return (
    <Transition visible={visible} animation="fade down" duration={1000}>
      <Card fluid>
        <Card.Content className="sl">
          <Card.Header>SL Statistics</Card.Header>
        </Card.Content>
        <Card.Content className="sl">
          <Grid>
            <Grid.Row columns={7}>
              <Grid.Column>
                <Statistic size="small">
                  <Statistic.Value>{states}</Statistic.Value>
                  <Statistic.Label className="sl-color">
                    Active States
                  </Statistic.Label>
                </Statistic>
              </Grid.Column>
              <Grid.Column>
                <Statistic size="small">
                  <Statistic.Value>{counties}</Statistic.Value>
                  <Statistic.Label>Counties</Statistic.Label>
                </Statistic>
              </Grid.Column>
              <Grid.Column>
                <Statistic size="small">
                  <Statistic.Value>{tile_count}</Statistic.Value>
                  <Statistic.Label>Total Tiles</Statistic.Label>
                </Statistic>
              </Grid.Column>
              <Grid.Column>
                <Statistic size="small">
                  <Statistic.Value>{tile_flown}</Statistic.Value>
                  <Statistic.Label>Tiles Flown</Statistic.Label>
                </Statistic>
              </Grid.Column>
              <Grid.Column>
                <Statistic size="small">
                  <Statistic.Value>{flown}%</Statistic.Value>
                  <Statistic.Label>Flown</Statistic.Label>
                </Statistic>
              </Grid.Column>
              <Grid.Column>
                <Statistic size="small">
                  <Statistic.Value>{tile_shipped}</Statistic.Value>
                  <Statistic.Label>Tiles Shipped</Statistic.Label>
                </Statistic>
              </Grid.Column>
              <Grid.Column>
                <Statistic size="small">
                  <Statistic.Value>{shipped}%</Statistic.Value>
                  <Statistic.Label>Shipped</Statistic.Label>
                </Statistic>
              </Grid.Column>
            </Grid.Row>
          </Grid>
        </Card.Content>
      </Card>
    </Transition>
  );
}

export default SlStatistics;
