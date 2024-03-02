import React, { useState, useEffect, Fragment } from "react";
import axios from "axios";
import { Card, Divider } from "semantic-ui-react";
import "semantic-ui-css/semantic.min.css";

import ToShipWidget from "./ReadyToShipWidget";
import EasementsWithMultipleCoveragesWidget from "./EasementsWithMultipleCoveragesWidget";
import EoWidget from "./EoTrackerWidget";
function AtAGlance() {
  const [records, setRecords] = useState();

  useEffect(() => {
    axios
      .get("/widgets.json", {
        params: {
          ready_to_ship: true,
          eo_tracker: true,
          easements_with_multiple_coverages: true,
        },
      })
      .then((response) => {
        setRecords(response.data);
      })
      .catch((error) => {
        console.log(error);
      });
  }, []);
  // console.log(records)
  return (
    <Fragment>
      <Card.Group stackable itemsPerRow={3}>
        {records && <ToShipWidget records={records.ready_to_ship} />}
        {records && (
          <EasementsWithMultipleCoveragesWidget
            records={records.easements_with_multiple_coverages}
          />
        )}
        {records && <EoWidget records={records.eo_tracker} />}
      </Card.Group>
      <Divider />
    </Fragment>
  );
}

export default AtAGlance;
